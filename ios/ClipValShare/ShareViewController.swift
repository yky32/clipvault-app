import UIKit
import UniformTypeIdentifiers

/// System share sheet → App Group → open host app (`clipval://share`).
///
/// Keeps all data on-device (group.com.clipval). No network.
final class ShareViewController: UIViewController {
  private static let appGroupId = "group.com.clipval"
  private static let valueKey = "pending_share_value"
  private static let titleKey = "pending_share_title"
  private static let atKey = "pending_share_at"

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Transparent host; process attachments immediately.
    view.backgroundColor = .clear
    processShare()
  }

  private func processShare() {
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = extensionItem.attachments,
          !attachments.isEmpty
    else {
      finish()
      return
    }

    let group = DispatchGroup()
    var textParts: [String] = []
    var titleHint: String?

    if let subject = extensionItem.attributedContentText?.string,
       !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      titleHint = String(subject.prefix(80))
    }

    for provider in attachments {
      if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
          defer { group.leave() }
          if let s = item as? String {
            textParts.append(s)
          } else if let data = item as? Data, let s = String(data: data, encoding: .utf8) {
            textParts.append(s)
          }
        }
      } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
          defer { group.leave() }
          if let url = item as? URL {
            textParts.append(url.absoluteString)
            if titleHint == nil {
              titleHint = url.host.map { String($0.prefix(60)) }
            }
          }
        }
      } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
          defer { group.leave() }
          if let s = item as? String {
            textParts.append(s)
          }
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      guard let self else { return }
      let value = textParts
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")

      if !value.isEmpty {
        self.persist(value: value, title: titleHint)
        self.openHostApp()
      }
      // Brief delay so openURL can fire before extension tears down.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        self.finish()
      }
    }
  }

  private func persist(value: String, title: String?) {
    guard let defaults = UserDefaults(suiteName: Self.appGroupId) else { return }
    defaults.set(value, forKey: Self.valueKey)
    if let title, !title.isEmpty {
      defaults.set(title, forKey: Self.titleKey)
    } else {
      defaults.removeObject(forKey: Self.titleKey)
    }
    defaults.set(Date().timeIntervalSince1970, forKey: Self.atKey)
    defaults.synchronize()
  }

  private func openHostApp() {
    guard let url = URL(string: "clipval://share") else { return }
    var responder: UIResponder? = self
    while let current = responder {
      if let application = current as? UIApplication {
        application.open(url, options: [:], completionHandler: nil)
        return
      }
      // UIApplication is not always reachable from extensions; try selector openURL.
      if current.responds(to: Selector(("openURL:options:completionHandler:"))) {
        // Prefer modern open if available via perform — fall through to extensionContext.
      }
      responder = current.next
    }
    extensionContext?.open(url, completionHandler: nil)
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
