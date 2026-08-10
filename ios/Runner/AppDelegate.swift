import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroupId = "group.com.clipval"
  private static let shareValueKey = "pending_share_value"
  private static let shareTitleKey = "pending_share_title"
  private static let shareAtKey = "pending_share_at"

  private let cloudKitSync = CloudKitSyncChannel()
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
    return ok
  }

  /// Also catch late window attach (iOS 13+ scenes).
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerNativeChannelsWhenReady(attemptsLeft: 5)
  }

  private func registerNativeChannelsWhenReady(attemptsLeft: Int) {
    if nativeChannelsRegistered { return }

    if let messenger = flutterBinaryMessenger() {
      registerShareChannel(with: messenger)
      cloudKitSync.register(with: messenger)
      nativeChannelsRegistered = true
      NSLog("[ClipVal] Native channels registered (share + icloud_sync)")
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
}
