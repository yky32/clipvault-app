import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroupId = "group.com.clipval"
  private static let shareValueKey = "pending_share_value"
  private static let shareTitleKey = "pending_share_title"
  private static let shareAtKey = "pending_share_at"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Flutter may attach the engine after super; register on next runloop tick.
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let controller = self.window?.rootViewController as? FlutterViewController {
        self.registerShareChannel(with: controller.binaryMessenger)
      }
    }
    return ok
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
