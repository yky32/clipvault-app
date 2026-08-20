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

/// Medium holds up to 8; large up to 16. Columns adapt to item count.
private let mediumCapacity = 8
private let largeCapacity = 16

struct WidgetItem: Codable, Identifiable, Hashable {
  let id: String
  let title: String
  let value: String
  /// Optional letter from host when titles are masked.
  let monogram: String?
  let pinned: Bool?

  var displayMonogram: String {
    if let m = monogram?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty {
      return String(m.prefix(1)).uppercased()
    }
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let c = t.first else { return "•" }
    return String(c).uppercased()
  }

  var displayTitle: String {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty { return "···" }
    return t
  }
}

struct WidgetPayload: Codable {
  let items: [WidgetItem]
  let updatedAt: String?
  let hideTitles: Bool?
  let pinnedOnly: Bool?
}

// MARK: - Timeline

struct ClipValEntry: TimelineEntry {
  let date: Date
  let items: [WidgetItem]
  let justCopiedId: String?
  let hideTitles: Bool
  let pinnedOnly: Bool
}

struct ClipValProvider: TimelineProvider {
  func placeholder(in context: Context) -> ClipValEntry {
    ClipValEntry(
      date: .now,
      items: (1...8).map {
        WidgetItem(id: "\($0)", title: "Item \($0)", value: "", monogram: nil, pinned: nil)
      },
      justCopiedId: nil,
      hideTitles: false,
      pinnedOnly: false
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
    let loaded = loadPayload()
    return ClipValEntry(
      date: date,
      items: loaded.items,
      justCopiedId: loadCopied(at: date),
      hideTitles: loaded.hideTitles,
      pinnedOnly: loaded.pinnedOnly
    )
  }

  private func loadPayload() -> (items: [WidgetItem], hideTitles: Bool, pinnedOnly: Bool) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.synchronize()
    guard let raw = defaults?.string(forKey: itemsKey),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
    else { return ([], false, false) }
    return (
      Array(payload.items.prefix(largeCapacity)),
      payload.hideTitles ?? false,
      payload.pinnedOnly ?? false
    )
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
// IMPORTANT: Do NOT pass the vault value as an AppIntent parameter.
// iOS silently truncates / empties large or special intent params → clipboard
// ends up empty in production. Always resolve value from App Group by id.

@available(iOS 17.0, *)
struct CopyValueIntent: AppIntent {
  static var title: LocalizedStringResource = "Copy"
  static var openAppWhenRun: Bool = false
  static var isDiscoverable: Bool = false

  @Parameter(title: "ID") var id: String

  init() { id = "" }
  init(id: String) { self.id = id }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let resolved = Self.lookupItem(id: id)
    let value = resolved?.value ?? ""
    let title = {
      let t = (resolved?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if !t.isEmpty { return t }
      if let m = resolved?.monogram, !m.isEmpty { return m }
      return "ClipVal"
    }()

    guard !value.isEmpty else {
      return .result(dialog: IntentDialog(stringLiteral: "Nothing to copy — open ClipVal to refresh the widget."))
    }

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

  /// Load plaintext value from the App Group snapshot written by the Flutter app.
  private static func lookupItem(id: String) -> WidgetItem? {
    guard !id.isEmpty,
          let defaults = UserDefaults(suiteName: appGroupId),
          let raw = defaults.string(forKey: itemsKey),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
    else { return nil }
    return payload.items.first { $0.id == id }
  }
}

// MARK: - UI: responsive grid — fills free space, scales by item count

struct ClipValWidgetEntryView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetFamily) private var family
  var entry: ClipValEntry

  private var capacity: Int {
    family == .systemLarge ? largeCapacity : mediumCapacity
  }

  private let gridSpacing: CGFloat = 6

  var body: some View {
    let items = Array(entry.items.prefix(capacity))

    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 0) {
        header
          .frame(height: 20)
          .padding(.bottom, 8)

        if items.isEmpty {
          emptyState
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          responsiveGrid(items: items, in: geo.size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 11)
      .padding(.bottom, 10)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
    }
    .widgetBackground()
  }

  private var header: some View {
    HStack(spacing: 6) {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(brand)
        .frame(width: 14, height: 14)
        .overlay(
          Image(systemName: "doc.on.clipboard")
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white)
        )
      Text(entry.pinnedOnly ? "Favorites" : "ClipVal")
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .lineLimit(1)
      Spacer(minLength: 6)
      Text(entry.justCopiedId == nil ? "Tap to copy" : "Copied ✓")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(entry.justCopiedId == nil ? .secondary : okGreen)
        .lineLimit(1)
    }
  }

  private var emptyState: some View {
    // Teach: pin favorites → widget shows them. Link opens app.
    Link(destination: URL(string: "clipval://vault")!) {
      VStack(spacing: 8) {
        Image(systemName: entry.pinnedOnly ? "pin.fill" : "plus.app.fill")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Color.accentColor.opacity(0.9))
        Text(entry.pinnedOnly
              ? "Pin favorites in ClipVal"
              : "Add values in ClipVal")
          .font(.system(size: 13, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
        Text(entry.pinnedOnly
              ? "Home Screen shows pinned items only"
              : "Then pin · they appear here for one-tap copy")
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(8)
    }
  }

  /// Columns adapt to count so fewer items get bigger tap targets;
  /// rows share leftover height so large widgets don’t leave a blank band.
  private func responsiveGrid(items: [WidgetItem], in size: CGSize) -> some View {
    let cols = columnCount(for: items.count)
    let rows = chunk(items, size: cols)
    let rowCount = max(rows.count, 1)
    // Header (~28) + vertical padding (~21) reserved outside the grid.
    let gridHeight = max(size.height - 49, 40)
    let cellHeight = (gridHeight - gridSpacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)
    let cellWidth = (size.width - 24 - gridSpacing * CGFloat(cols - 1)) / CGFloat(cols)
    let metrics = CellMetrics(
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      family: family
    )

    return VStack(spacing: gridSpacing) {
      ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: gridSpacing) {
          ForEach(row) { item in
            cell(
              item,
              hot: item.id == entry.justCopiedId,
              hideTitle: entry.hideTitles,
              metrics: metrics
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          // Incomplete last row — equal empty slots so remaining cells stay full-width.
          if row.count < cols {
            ForEach(0..<(cols - row.count), id: \.self) { _ in
              Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// Pick columns so the grid uses space without looking sparse.
  private func columnCount(for count: Int) -> Int {
    let n = max(count, 1)
    if family == .systemLarge {
      switch n {
      case 1: return 1
      case 2: return 2
      case 3: return 3
      case 4: return 2          // 2×2 — roomy tiles
      case 5...6: return 3      // 2 rows
      case 7...9: return 3      // 3 rows
      default: return 4         // 10–16 → 3–4 rows
      }
    }
    // Medium: always aim for a short wide strip
    switch n {
    case 1: return 1
    case 2: return 2
    case 3: return 3
    default: return 4
    }
  }

  private func chunk(_ items: [WidgetItem], size: Int) -> [[WidgetItem]] {
    guard size > 0 else { return [items] }
    var out: [[WidgetItem]] = []
    var i = 0
    while i < items.count {
      let end = min(i + size, items.count)
      out.append(Array(items[i..<end]))
      i = end
    }
    return out
  }

  private func cell(
    _ item: WidgetItem,
    hot: Bool,
    hideTitle: Bool,
    metrics: CellMetrics
  ) -> some View {
    let shownTitle = hideTitle ? "···" : item.displayTitle
    let label = VStack(spacing: metrics.stackSpacing) {
      ZStack {
        Circle()
          .fill(hot ? okGreen : brand.opacity(colorScheme == .dark ? 0.30 : 0.13))
        if hot {
          Image(systemName: "checkmark")
            .font(.system(size: metrics.checkSize, weight: .bold))
            .foregroundStyle(.white)
        } else {
          Text(item.displayMonogram)
            .font(.system(size: metrics.monoSize, weight: .bold, design: .rounded))
            .foregroundStyle(brand)
        }
      }
      .frame(width: metrics.monoFrame, height: metrics.monoFrame)

      Text(shownTitle)
        .font(.system(size: metrics.titleSize, weight: .semibold, design: .rounded))
        .foregroundStyle(hot ? okGreen : .primary)
        .lineLimit(metrics.titleLines)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, metrics.padV)
    .padding(.horizontal, metrics.padH)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
        .fill(hot ? okGreen.opacity(0.12) : cellFill)
    )
    .overlay(
      RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
        .strokeBorder(hot ? okGreen.opacity(0.35) : Color.primary.opacity(0.05), lineWidth: 1)
    )
    .contentShape(RoundedRectangle(cornerRadius: metrics.corner, style: .continuous))

    return Group {
      if #available(iOS 17.0, *) {
        // Only pass id — value is loaded from App Group inside the intent.
        Button(intent: CopyValueIntent(id: item.id)) {
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

/// Type scale / padding derived from actual cell size so sparse grids grow.
private struct CellMetrics {
  let monoFrame: CGFloat
  let monoSize: CGFloat
  let checkSize: CGFloat
  let titleSize: CGFloat
  let titleLines: Int
  let stackSpacing: CGFloat
  let padV: CGFloat
  let padH: CGFloat
  let corner: CGFloat

  init(cellWidth: CGFloat, cellHeight: CGFloat, family: WidgetFamily) {
    let shortSide = min(max(cellWidth, 1), max(cellHeight, 1))
    // Monogram ~38% of short side, clamped for readability.
    monoFrame = min(max(shortSide * 0.38, 22), family == .systemLarge ? 48 : 32)
    monoSize = monoFrame * 0.42
    checkSize = monoFrame * 0.38
    titleSize = min(max(shortSide * 0.12, 9), family == .systemLarge ? 13 : 11)
    titleLines = cellHeight >= 72 ? 2 : 1
    stackSpacing = cellHeight >= 70 ? 6 : 3
    padV = cellHeight >= 70 ? 10 : 4
    padH = cellWidth >= 90 ? 6 : 2
    corner = cellHeight >= 70 ? 14 : 10
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

// MARK: - Widget (medium 4×2 · large 4×4)

struct ClipValWidget: Widget {
  let kind = "ClipValWidget"

  var body: some WidgetConfiguration {
    if #available(iOS 17.0, *) {
      return StaticConfiguration(kind: kind, provider: ClipValProvider()) { entry in
        ClipValWidgetEntryView(entry: entry)
      }
      .configurationDisplayName("ClipVal")
      .description("Tap to copy without opening the app. Medium 8 · large 16.")
      .supportedFamilies([.systemMedium, .systemLarge])
      .contentMarginsDisabled()
    } else {
      return StaticConfiguration(kind: kind, provider: ClipValProvider()) { entry in
        ClipValWidgetEntryView(entry: entry)
      }
      .configurationDisplayName("ClipVal")
      .description("Tap to copy. Pin items as favorites. Medium or large.")
      .supportedFamilies([.systemMedium, .systemLarge])
    }
  }
}
