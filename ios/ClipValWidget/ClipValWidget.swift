import WidgetKit
import SwiftUI
import UIKit
import AppIntents

// MARK: - App Group

private let appGroupId = "group.com.clipval"
private let itemsKey = "widget_items_json"
private let copiedIdKey = "widget_copied_id"
private let copiedAtKey = "widget_copied_at"
private let copiedHighlightSeconds: TimeInterval = 2.6

private let brand = Color(red: 0.76, green: 0.36, blue: 0.28)
private let okGreen = Color(red: 0.15, green: 0.55, blue: 0.35)

/// 4 columns × 2 rows
private let gridColumns = 4
private let gridRows = 2
private let gridCapacity = gridColumns * gridRows // 8

struct WidgetItem: Codable, Identifiable, Hashable {
  let id: String
  let title: String
  let value: String

  var monogram: String {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let c = t.first else { return "•" }
    return String(c).uppercased()
  }
}

struct WidgetPayload: Codable {
  let items: [WidgetItem]
  let updatedAt: String?
}

// MARK: - Timeline

struct ClipValEntry: TimelineEntry {
  let date: Date
  let items: [WidgetItem]
  let justCopiedId: String?
}

struct ClipValProvider: TimelineProvider {
  func placeholder(in context: Context) -> ClipValEntry {
    ClipValEntry(
      date: .now,
      items: (1...8).map {
        WidgetItem(id: "\($0)", title: "Item \($0)", value: "")
      },
      justCopiedId: nil
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ClipValEntry) -> Void) {
    completion(entry(at: .now))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ClipValEntry>) -> Void) {
    let now = Date()
    let e = entry(at: now)
    var policy: TimelineReloadPolicy = .after(
      Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
    )
    if let ts = UserDefaults(suiteName: appGroupId)?.double(forKey: copiedAtKey), ts > 0 {
      let exp = Date(timeIntervalSince1970: ts).addingTimeInterval(copiedHighlightSeconds)
      if exp > now { policy = .after(exp) }
    }
    completion(Timeline(entries: [e], policy: policy))
  }

  private func entry(at date: Date) -> ClipValEntry {
    ClipValEntry(date: date, items: loadItems(), justCopiedId: loadCopied(at: date))
  }

  private func loadItems() -> [WidgetItem] {
    guard let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: itemsKey),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
    else { return [] }
    return Array(payload.items.prefix(gridCapacity))
  }

  private func loadCopied(at date: Date) -> String? {
    guard let d = UserDefaults(suiteName: appGroupId),
          let id = d.string(forKey: copiedIdKey), !id.isEmpty else { return nil }
    let ts = d.double(forKey: copiedAtKey)
    guard ts > 0 else { return nil }
    let age = date.timeIntervalSince1970 - ts
    return (age >= 0 && age <= copiedHighlightSeconds) ? id : nil
  }
}

// MARK: - Copy (no app open on iOS 17+)

@available(iOS 17.0, *)
struct CopyValueIntent: AppIntent {
  static var title: LocalizedStringResource = "Copy"
  static var openAppWhenRun: Bool = false

  @Parameter(title: "ID") var id: String
  @Parameter(title: "Value") var value: String
  @Parameter(title: "Title") var title: String

  init() { id = ""; value = ""; title = "" }
  init(id: String, value: String, title: String) {
    self.id = id; self.value = value; self.title = title
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    UIPasteboard.general.string = value
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    if let d = UserDefaults(suiteName: appGroupId) {
      d.set(id, forKey: copiedIdKey)
      d.set(Date().timeIntervalSince1970, forKey: copiedAtKey)
      d.synchronize()
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")
    return .result(dialog: IntentDialog(stringLiteral: "Copied “\(title)”"))
  }
}

// MARK: - UI: 4 columns × max 2 rows (medium only)

struct ClipValWidgetEntryView: View {
  @Environment(\.colorScheme) private var colorScheme
  var entry: ClipValEntry

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 5, alignment: .center),
    count: gridColumns
  )

  var body: some View {
    let items = Array(entry.items.prefix(gridCapacity))

    VStack(alignment: .leading, spacing: 0) {
      // Header — reserved band so title never fights the grid
      HStack(spacing: 6) {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(brand)
          .frame(width: 14, height: 14)
          .overlay(
            Image(systemName: "doc.on.clipboard")
              .font(.system(size: 7, weight: .bold))
              .foregroundStyle(.white)
          )
        Text("ClipVal")
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Spacer(minLength: 6)
        Text(entry.justCopiedId == nil ? "Tap to copy" : "Copied ✓")
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundStyle(entry.justCopiedId == nil ? .secondary : okGreen)
          .lineLimit(1)
      }
      .frame(height: 20)
      .padding(.bottom, 8)

      if items.isEmpty {
        Spacer(minLength: 0)
        Text("Open ClipVal to add values")
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
        Spacer(minLength: 0)
      } else {
        // 4 per row × max 2 rows — compact cells
        LazyVGrid(columns: columns, alignment: .center, spacing: 5) {
          ForEach(items) { item in
            cell(item, hot: item.id == entry.justCopiedId)
          }
        }
        Spacer(minLength: 0)
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 11)
    .padding(.bottom, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetBackground()
  }

  /// Compact cell: smaller monogram + title under it.
  private func cell(_ item: WidgetItem, hot: Bool) -> some View {
    let label = VStack(spacing: 3) {
      ZStack {
        Circle()
          .fill(hot ? okGreen : brand.opacity(colorScheme == .dark ? 0.30 : 0.13))
        if hot {
          Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
        } else {
          Text(item.monogram)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(brand)
        }
      }
      .frame(width: 28, height: 28)

      Text(item.title)
        .font(.system(size: 9, weight: .semibold, design: .rounded))
        .foregroundStyle(hot ? okGreen : .primary)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 2)
    .frame(maxWidth: .infinity)
    .frame(minHeight: 52)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(hot ? okGreen.opacity(0.12) : cellFill)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(hot ? okGreen.opacity(0.35) : Color.primary.opacity(0.05), lineWidth: 1)
    )
    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

    return Group {
      if #available(iOS 17.0, *) {
        Button(intent: CopyValueIntent(id: item.id, value: item.value, title: item.title)) {
          label
        }
        .buttonStyle(.plain)
      } else {
        Link(destination: URL(string: "clipval://copy?id=\(item.id)")!) {
          label
        }
      }
    }
  }

  private var cellFill: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.08)
      : Color.black.opacity(0.04)
  }
}

private extension View {
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) {
        Color(UIColor.systemBackground)
      }
    } else {
      background(Color(UIColor.systemBackground))
    }
  }
}

// MARK: - Widget (medium only — 4×2 grid)

struct ClipValWidget: Widget {
  let kind = "ClipValWidget"

  var body: some WidgetConfiguration {
    if #available(iOS 17.0, *) {
      return StaticConfiguration(kind: kind, provider: ClipValProvider()) { entry in
        ClipValWidgetEntryView(entry: entry)
      }
      .configurationDisplayName("ClipVal")
      .description("4×2 grid — tap to copy without opening the app.")
      .supportedFamilies([.systemMedium])
      .contentMarginsDisabled()
    } else {
      return StaticConfiguration(kind: kind, provider: ClipValProvider()) { entry in
        ClipValWidgetEntryView(entry: entry)
      }
      .configurationDisplayName("ClipVal")
      .description("4×2 grid — tap to copy.")
      .supportedFamilies([.systemMedium])
    }
  }
}
