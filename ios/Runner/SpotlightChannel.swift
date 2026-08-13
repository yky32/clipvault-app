import CoreSpotlight
import Flutter
import UIKit
import UniformTypeIdentifiers

/// Indexes vault **titles only** into Spotlight (never values).
final class SpotlightChannel: NSObject {
  static let channelName = "com.clipval/spotlight"
  static let domain = "com.clipval.vault"

  private var channel: FlutterMethodChannel?

  func register(with messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel = ch
    ch.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "indexItems":
      guard let args = call.arguments as? [[String: Any]] else {
        result(FlutterError(code: "bad_args", message: "expected list", details: nil))
        return
      }
      index(args, result: result)
    case "deleteItems":
      guard let ids = call.arguments as? [String] else {
        result(FlutterError(code: "bad_args", message: "expected id list", details: nil))
        return
      }
      CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids) { error in
        if let error {
          result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    case "deleteAll":
      CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [Self.domain]) { error in
        if let error {
          result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func index(_ rows: [[String: Any]], result: @escaping FlutterResult) {
    var items: [CSSearchableItem] = []
    items.reserveCapacity(rows.count)
    for row in rows {
      guard let id = row["id"] as? String, !id.isEmpty else { continue }
      let title = (row["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if title.isEmpty { continue }

      let set = CSSearchableItemAttributeSet(contentType: UTType.text)
      set.title = title
      set.displayName = title
      // Explicitly do NOT index the secret value.
      set.contentDescription = "ClipVal · tap to copy"
      set.keywords = ["ClipVal", title]

      let item = CSSearchableItem(
        uniqueIdentifier: id,
        domainIdentifier: Self.domain,
        attributeSet: set
      )
      item.expirationDate = .distantFuture
      items.append(item)
    }

    guard !items.isEmpty else {
      result(nil)
      return
    }

    CSSearchableIndex.default().indexSearchableItems(items) { error in
      if let error {
        result(FlutterError(code: "index_failed", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  /// Open clipval://copy?id=… when user taps a Spotlight result.
  static func handleUserActivity(_ userActivity: NSUserActivity) -> URL? {
    guard userActivity.activityType == CSSearchableItemActionType else { return nil }
    let key = CSSearchableItemActivityIdentifier
    guard let id = userActivity.userInfo?[key] as? String, !id.isEmpty else { return nil }
    var components = URLComponents()
    components.scheme = "clipval"
    components.host = "copy"
    components.queryItems = [URLQueryItem(name: "id", value: id)]
    return components.url
  }
}
