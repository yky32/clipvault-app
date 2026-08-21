import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroupId = "group.com.clipval"
  private static let shareValueKey = "pending_share_value"
  private static let shareTitleKey = "pending_share_title"
  private static let shareAtKey = "pending_share_at"

  private let cloudKitSync = CloudKitSyncChannel()
  private let spotlight = SpotlightChannel()
  private var nativeChannelsRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Scene-based embedding often has nil `window` at launch. Retry until
    // FlutterViewController is available so method channels attach.
    registerNativeChannelsWhenReady(attemptsLeft: 20)
    Self.rehydratePendingWidgetPaste()
    return ok
  }

  /// Also catch late window attach (iOS 13+ scenes).
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerNativeChannelsWhenReady(attemptsLeft: 5)
    // Re-apply widget copy onto system pasteboard (extension writes are flaky).
    Self.rehydratePendingWidgetPaste()
  }

  /// If widget App Intent stashed a recent value, ensure UIPasteboard.general has it.
  private static func rehydratePendingWidgetPaste() {
    let defaults = UserDefaults(suiteName: appGroupId)
    guard let value = defaults?.string(forKey: "widget_pending_paste_value"),
          !value.isEmpty
    else { return }
    let at = defaults?.double(forKey: "widget_pending_paste_at") ?? 0
    // Only within 15 minutes
    guard at > 0, Date().timeIntervalSince1970 - at < 15 * 60 else {
      defaults?.removeObject(forKey: "widget_pending_paste_value")
      defaults?.removeObject(forKey: "widget_pending_paste_at")
      return
    }
    let pb = UIPasteboard.general
    if pb.string == value { return }
    pb.strings = [value]
    pb.string = value
    NSLog("[ClipVal] Rehydrated widget paste (%d chars)", value.count)
  }

  private func registerNativeChannelsWhenReady(attemptsLeft: Int) {
    if nativeChannelsRegistered { return }

    if let messenger = flutterBinaryMessenger() {
      registerShareChannel(with: messenger)
      registerWidgetChannel(with: messenger)
      cloudKitSync.register(with: messenger)
      spotlight.register(with: messenger)
      nativeChannelsRegistered = true
      NSLog("[ClipVal] Native channels registered (share + widget + icloud_sync + spotlight)")
      return
    }

    guard attemptsLeft > 0 else {
      NSLog("[ClipVal] WARNING: could not find FlutterViewController to register channels")
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.registerNativeChannelsWhenReady(attemptsLeft: attemptsLeft - 1)
    }
  }

  private func flutterBinaryMessenger() -> FlutterBinaryMessenger? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller.binaryMessenger
    }
    // Scene-based lifecycle: walk windows.
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let controller = window.rootViewController as? FlutterViewController {
          return controller.binaryMessenger
        }
        // Nested (e.g. nav/tab) — rare for Flutter shell but cheap to check.
        if let controller = findFlutterViewController(in: window.rootViewController) {
          return controller.binaryMessenger
        }
      }
    }
    return nil
  }

  private func findFlutterViewController(in root: UIViewController?) -> FlutterViewController? {
    guard let root else { return nil }
    if let f = root as? FlutterViewController { return f }
    for child in root.children {
      if let f = findFlutterViewController(in: child) { return f }
    }
    if let presented = root.presentedViewController {
      return findFlutterViewController(in: presented)
    }
    return nil
  }

  /// Flush / write App Group snapshot for WidgetKit + keyboard (authoritative).
  private func registerWidgetChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.clipval/widget",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "flushAndReload":
        Self.persistAndReloadWidget(json: nil, keyboardJson: nil)
        Self.rehydratePendingWidgetPaste()
        result(true)
      case "rehydratePaste":
        Self.rehydratePendingWidgetPaste()
        result(true)
      case "forcePasteboard":
        // Flutter deep-link copy — write system pasteboard from main app (reliable).
        guard let args = call.arguments as? [String: Any],
              let value = args["value"] as? String,
              !value.isEmpty
        else {
          result(
            FlutterError(code: "bad_args", message: "value required", details: nil)
          )
          return
        }
        let pb = UIPasteboard.general
        pb.strings = [value]
        pb.string = value
        let d = UserDefaults(suiteName: Self.appGroupId)
        d?.set(value, forKey: "widget_pending_paste_value")
        d?.set(Date().timeIntervalSince1970, forKey: "widget_pending_paste_at")
        d?.synchronize()
        result(true)
      case "writeSnapshot":
        // args: { json: String, keyboardJson: String? }
        guard let args = call.arguments as? [String: Any],
              let json = args["json"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args",
              message: "writeSnapshot requires json",
              details: nil
            )
          )
          return
        }
        let kb = args["keyboardJson"] as? String
        Self.persistAndReloadWidget(json: json, keyboardJson: kb)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Authoritative write into App Group: UserDefaults JSON + per-id values + file.
  private static func persistAndReloadWidget(json: String?, keyboardJson: String?) {
    let defaults = UserDefaults(suiteName: Self.appGroupId)
    if let json {
      defaults?.set(json, forKey: "widget_items_json")
      // Per-item values — Intent looks up by id only (never trust intent value params).
      if let data = json.data(using: .utf8),
         let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let items = obj["items"] as? [[String: Any]]
      {
        var valuesMap: [String: String] = [:]
        for item in items {
          guard let id = item["id"] as? String, !id.isEmpty else { continue }
          let value = (item["value"] as? String) ?? ""
          valuesMap[id] = value
          defaults?.set(value, forKey: "wv_\(id)")
        }
        // Atomic map for correct id→value (avoids stale per-key ghosts)
        if let mapData = try? JSONSerialization.data(withJSONObject: valuesMap) {
          defaults?.set(mapData, forKey: "widget_values_map")
        }
        defaults?.set(Array(valuesMap.keys), forKey: "widget_value_ids")
        // File backup in shared container
        if let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: Self.appGroupId
        ) {
          let file = container.appendingPathComponent("widget_items.json")
          try? json.data(using: .utf8)?.write(to: file, options: .atomic)
        }
      }
    }
    if let keyboardJson {
      defaults?.set(keyboardJson, forKey: "keyboard_items_json")
      if let data = keyboardJson.data(using: .utf8),
         let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let items = obj["items"] as? [[String: Any]]
      {
        var map: [String: String] = [:]
        if let existing = defaults?.data(forKey: "widget_values_map"),
           let obj = try? JSONSerialization.jsonObject(with: existing) as? [String: String] {
          map = obj
        }
        for item in items {
          guard let id = item["id"] as? String, !id.isEmpty else { continue }
          let value = (item["value"] as? String) ?? ""
          map[id] = value
          defaults?.set(value, forKey: "wv_\(id)")
        }
        if let mapData = try? JSONSerialization.data(withJSONObject: map) {
          defaults?.set(mapData, forKey: "widget_values_map")
        }
      }
    }
    defaults?.synchronize()
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  /// Drain pending share from the Share Extension App Group (one-shot).
  private func registerShareChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.clipval/share",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "takePendingShare" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let defaults = UserDefaults(suiteName: Self.appGroupId) else {
        result(nil)
        return
      }
      let value = defaults.string(forKey: Self.shareValueKey)
      let title = defaults.string(forKey: Self.shareTitleKey)
      defaults.removeObject(forKey: Self.shareValueKey)
      defaults.removeObject(forKey: Self.shareTitleKey)
      defaults.removeObject(forKey: Self.shareAtKey)
      defaults.synchronize()
      guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(nil)
        return
      }
      var map: [String: Any] = ["value": value]
      if let title, !title.isEmpty {
        map["title"] = title
      }
      result(map)
    }
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = SpotlightChannel.handleUserActivity(userActivity) {
      // Reuse widget deep-link path: clipval://copy?id=
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        _ = self.application(UIApplication.shared, open: url, options: [:])
      }
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

}
