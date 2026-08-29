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
    // Cold start from widget Link: copy ASAP before Flutter is ready.
    if let url = launchOptions?[.url] as? URL {
      Self.handleClipValCopyURL(url)
    }
    // Simulator / automation: -sim-copy-id <id> writes pasteboard without URL dialog.
    let args = ProcessInfo.processInfo.arguments
    if let idx = args.firstIndex(of: "-sim-copy-id"), args.index(after: idx) < args.endIndex {
      let id = args[args.index(after: idx)]
      if let value = Self.loadWidgetValue(for: id), !value.isEmpty {
        Self.writeSystemPasteboard(value)
        if let d = UserDefaults(suiteName: Self.appGroupId) {
          d.set(value, forKey: "widget_pending_paste_value")
          d.set(Date().timeIntervalSince1970, forKey: "widget_pending_paste_at")
          d.synchronize()
        }
        NSLog("[ClipVal] sim-copy-id wrote %d chars", value.count)
      } else {
        NSLog("[ClipVal] sim-copy-id missing value for %@", id)
      }
    }
    Self.rehydratePendingWidgetPaste()
    return ok
  }

  /// Widget `clipval://copy?id=` — write pasteboard in main app immediately.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let handled = Self.handleClipValCopyURL(url)
    let superOk = super.application(app, open: url, options: options)
    return handled || superOk
  }

  /// Also catch late window attach (iOS 13+ scenes).
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerNativeChannelsWhenReady(attemptsLeft: 5)
    // Re-apply widget copy. Do NOT bounce here — only bounce from copy URL handler
    // after multi-write (avoid racing empty pasteboard).
    Self.rehydratePendingWidgetPaste()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      Self.rehydratePendingWidgetPaste()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      Self.rehydratePendingWidgetPaste()
    }
  }

  /// Fresh widget copy (< 2.5s) → auto return Home after pasteboard write.
  private static func shouldBounceAfterWidgetCopy() -> Bool {
    let d = UserDefaults(suiteName: appGroupId)
    let at = d?.double(forKey: "widget_pending_paste_at") ?? 0
    guard at > 0 else { return false }
    let age = Date().timeIntervalSince1970 - at
    return age >= 0 && age < 2.5
  }

  /// If widget App Intent stashed a recent value, force system pasteboard.
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
    writeSystemPasteboard(value)
    NSLog("[ClipVal] Rehydrated widget paste (%d chars)", value.count)
  }

  /// Handle `clipval://copy?id=` from Home Screen widget Link.
  @discardableResult
  private static func handleClipValCopyURL(_ url: URL) -> Bool {
    guard url.scheme == "clipval" else { return false }
    let host = (url.host ?? "").lowercased()
    let path = url.path.lowercased()
    let isCopy = host == "copy" || path == "/copy" || path.hasPrefix("/copy/")
    guard isCopy else { return false }

    let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first(where: { $0.name == "id" })?
      .value?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let id, !id.isEmpty else {
      NSLog("[ClipVal] copy URL missing id: %@", url.absoluteString)
      return true
    }

    guard let value = loadWidgetValue(for: id), !value.isEmpty else {
      NSLog("[ClipVal] copy URL: no value in App Group for id %@", id)
      // Still mark bounce so we don't leave user stuck if Flutter also fails
      if let d = UserDefaults(suiteName: appGroupId) {
        d.set(true, forKey: "widget_bounce_pending")
        d.synchronize()
      }
      return true
    }

    // Write pasteboard FIRST and hard (main app process)
    writeSystemPasteboard(value)
    if let d = UserDefaults(suiteName: appGroupId) {
      d.set(value, forKey: "widget_pending_paste_value")
      d.set(Date().timeIntervalSince1970, forKey: "widget_pending_paste_at")
      d.set(id, forKey: "widget_copied_id")
      d.set(Date().timeIntervalSince1970, forKey: "widget_copied_at")
      d.set(true, forKey: "widget_bounce_pending")
      d.synchronize()
    }
    // Second write after short delay (some iOS builds drop first write on open)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      Self.writeSystemPasteboard(value)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      Self.writeSystemPasteboard(value)
    }
    // Bounce Home only after pasteboard has been written multiple times
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
      Self.writeSystemPasteboard(value)
      if UserDefaults(suiteName: Self.appGroupId)?.bool(forKey: "widget_bounce_pending") == true {
        UserDefaults(suiteName: Self.appGroupId)?.set(false, forKey: "widget_bounce_pending")
        Self.moveToBackground()
      }
    }
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")
    }
    NSLog("[ClipVal] Native copy from widget URL (%d chars, id=%@)", value.count, id)
    return true
  }

  /// Return to Home / previous app after widget copy (best-effort).
  private static func moveToBackground() {
    UIControl().sendAction(
      Selector(("suspend")),
      to: UIApplication.shared,
      for: nil
    )
  }

  // 🔒 LOCKED: plain string only — see docs/HOME_WIDGET.md
  private static func writeSystemPasteboard(_ value: String) {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      NSLog("[ClipVal] refuse empty pasteboard write")
      return
    }
    let pb = UIPasteboard.general
    // Do not clear first (nil write races with other apps reading empty).
    pb.string = trimmed
    pb.strings = [trimmed]
    let ok = (pb.string == trimmed)
    NSLog(
      "[ClipVal] pasteboard write chars=%d ok=%@ preview=%@",
      trimmed.count,
      ok ? "YES" : "NO",
      String(trimmed.prefix(32))
    )
  }

  private static func loadWidgetValue(for id: String) -> String? {
    let d = UserDefaults(suiteName: appGroupId)
    d?.synchronize()
    if let v = d?.string(forKey: "wv_\(id)"), !v.isEmpty { return v }
    if let mapData = d?.data(forKey: "widget_values_map"),
       let map = try? JSONSerialization.jsonObject(with: mapData) as? [String: Any],
       let v = map[id] as? String, !v.isEmpty
    {
      return v
    }
    if let raw = d?.string(forKey: "widget_items_json"),
       let data = raw.data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let items = obj["items"] as? [[String: Any]],
       let item = items.first(where: { ($0["id"] as? String) == id }),
       let v = item["value"] as? String,
       !v.isEmpty
    {
      return v
    }
    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId
    ) {
      let file = container.appendingPathComponent("widget_items.json")
      if let data = try? Data(contentsOf: file),
         let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let items = obj["items"] as? [[String: Any]],
         let item = items.first(where: { ($0["id"] as? String) == id }),
         let v = item["value"] as? String,
         !v.isEmpty
      {
        return v
      }
    }
    return nil
  }

  private static func loadWidgetTitle(for id: String) -> String? {
    let d = UserDefaults(suiteName: appGroupId)
    d?.synchronize()
    if let raw = d?.string(forKey: "widget_items_json"),
       let data = raw.data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let items = obj["items"] as? [[String: Any]],
       let item = items.first(where: { ($0["id"] as? String) == id })
    {
      if let t = item["title"] as? String, !t.isEmpty { return t }
      if let t = item["displayTitle"] as? String, !t.isEmpty { return t }
    }
    return nil
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
      case "moveToBackground":
        DispatchQueue.main.async {
          Self.moveToBackground()
        }
        result(true)
      case "cancelBounce":
        UserDefaults(suiteName: Self.appGroupId)?.set(false, forKey: "widget_bounce_pending")
        result(true)
      case "bounceIfWidgetCopy":
        DispatchQueue.main.async {
          let d = UserDefaults(suiteName: Self.appGroupId)
          guard d?.bool(forKey: "widget_bounce_pending") == true else {
            return
          }
          Self.rehydratePendingWidgetPaste()
          d?.set(false, forKey: "widget_bounce_pending")
          // Delay bounce so pasteboard is stable
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            Self.rehydratePendingWidgetPaste()
            Self.moveToBackground()
          }
        }
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
        Self.writeSystemPasteboard(value)
        let d = UserDefaults(suiteName: Self.appGroupId)
        d?.set(value, forKey: "widget_pending_paste_value")
        d?.set(Date().timeIntervalSince1970, forKey: "widget_pending_paste_at")
        d?.synchronize()
        result(true)
      case "forcePasteboardById":
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              !id.isEmpty
        else {
          result(
            FlutterError(code: "bad_args", message: "id required", details: nil)
          )
          return
        }
        guard let value = Self.loadWidgetValue(for: id), !value.isEmpty else {
          result(
            FlutterError(code: "not_found", message: "no value for id", details: id)
          )
          return
        }
        Self.writeSystemPasteboard(value)
        let d2 = UserDefaults(suiteName: Self.appGroupId)
        d2?.set(value, forKey: "widget_pending_paste_value")
        d2?.set(Date().timeIntervalSince1970, forKey: "widget_pending_paste_at")
        d2?.synchronize()
        let title = Self.loadWidgetTitle(for: id) ?? ""
        result([
          "chars": value.count,
          "preview": String(value.prefix(40)),
          "title": title,
        ])
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
        if let copyOpens = obj["copyOpensApp"] as? Bool {
          defaults?.set(copyOpens, forKey: "widget_copy_opens_app")
        }
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
