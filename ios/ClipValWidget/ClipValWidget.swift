import WidgetKit
import SwiftUI
import UIKit
import AppIntents

// MARK: - App Group

private let appGroupId = "group.com.clipval"
private let itemsKey = "widget_items_json"
private let copiedIdKey = "widget_copied_id"
private let copiedAtKey = "widget_copied_at"
private let copiedHighlightSeconds: TimeInterval = 3.5

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
    let loaded = loadPayload()
    let activeCopy = loadCopied(at: now)

    // Entry 1: current UI (green tick if copy is fresh)
    var entries: [ClipValEntry] = [
      ClipValEntry(
        date: now,
        items: loaded.items,
        justCopiedId: activeCopy,
        hideTitles: loaded.hideTitles,
        pinnedOnly: loaded.pinnedOnly
      ),
    ]

    // Entry 2: clear green tick after highlight window.
    // WidgetKit does not run timers — without a second entry the checkmark
    // sticks until the next 30‑min reload → feels laggy / broken.
    if activeCopy != nil,
       let exp = copyExpiryDate(),
       exp > now
    {
      entries.append(
        ClipValEntry(
          date: exp,
          items: loaded.items,
          justCopiedId: nil,
          hideTitles: loaded.hideTitles,
          pinnedOnly: loaded.pinnedOnly
        )
      )
      completion(Timeline(entries: entries, policy: .after(exp.addingTimeInterval(0.5))))
      return
    }

    let later =
      Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
    completion(Timeline(entries: entries, policy: .after(later)))
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
    guard let raw = defaults?.string(forKey: itemsKey) ?? {
      if let data = defaults?.data(forKey: itemsKey) {
        return String(data: data, encoding: .utf8)
      }
      return nil
    }(),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
    else { return ([], false, false) }
    return (
      Array(payload.items.prefix(largeCapacity)),
      payload.hideTitles ?? false,
      payload.pinnedOnly ?? false
    )
  }

  private func copyExpiryDate() -> Date? {
    guard let d = UserDefaults(suiteName: appGroupId) else { return nil }
    let ts = d.double(forKey: copiedAtKey)
    guard ts > 0 else { return nil }
    return Date(timeIntervalSince1970: ts).addingTimeInterval(copiedHighlightSeconds)
  }

  private func loadCopied(at date: Date) -> String? {
    guard let d = UserDefaults(suiteName: appGroupId),
          let id = d.string(forKey: copiedIdKey), !id.isEmpty else { return nil }
    let ts = d.double(forKey: copiedAtKey)
    guard ts > 0 else { return nil }
    let age = date.timeIntervalSince1970 - ts
    if age > copiedHighlightSeconds {
      // Stale highlight — drop so we never show forever-green after wake.
      d.removeObject(forKey: copiedIdKey)
      d.removeObject(forKey: copiedAtKey)
      d.synchronize()
      return nil
    }
    if age < 0 { return nil }
    return id
  }
}

// MARK: - Copy (iOS 17+, no app launch)
// CRITICAL: Intent takes ONLY itemID. Value is always loaded from App Group by that id.
// Passing `value` as an AppIntent parameter caused wrong-item copies (param mix-up).

private let pendingPasteValueKey = "widget_pending_paste_value"
private let pendingPasteAtKey = "widget_pending_paste_at"
private let valuesMapKey = "widget_values_map"

@available(iOS 17.0, *)
struct CopyVaultItemIntent: AppIntent {
  static var title: LocalizedStringResource = "Copy ClipVal Item"
  static var openAppWhenRun: Bool = false
  static var isDiscoverable: Bool = false

  /// Stable vault item id — the only input.
  @Parameter(title: "Item ID")
  var itemID: String

  init() {
    itemID = ""
  }

  init(itemID: String) {
    self.itemID = itemID
  }

  static var parameterSummary: some ParameterSummary {
    Summary("Copy \(\.$itemID)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let id = itemID.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !id.isEmpty else {
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      return .result(dialog: IntentDialog(stringLiteral: "Copy failed"))
    }

    guard let text = Self.loadValue(for: id), !text.isEmpty else {
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      return .result(dialog: IntentDialog(stringLiteral: "Open ClipVal once to refresh widget"))
    }

    // Instant feedback BEFORE pasteboard (timeline reload is slow otherwise)
    if let d = UserDefaults(suiteName: appGroupId) {
      d.set(id, forKey: copiedIdKey)
      d.set(Date().timeIntervalSince1970, forKey: copiedAtKey)
      d.set(text, forKey: pendingPasteValueKey)
      d.set(Date().timeIntervalSince1970, forKey: pendingPasteAtKey)
      d.set(text, forKey: "last_widget_copy_value")
      d.set(id, forKey: "last_widget_copy_id")
      d.synchronize()
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")

    // Strong haptic so user feels the tap landed
    let impact = UIImpactFeedbackGenerator(style: .medium)
    impact.prepare()
    impact.impactOccurred(intensity: 1.0)
    UINotificationFeedbackGenerator().notificationOccurred(.success)

    // System pasteboard
    let pb = UIPasteboard.general
    pb.strings = [text]
    pb.string = text
    let ok = (pb.string == text)

    if !ok {
      if let d = UserDefaults(suiteName: appGroupId) {
        d.removeObject(forKey: copiedIdKey)
        d.removeObject(forKey: copiedAtKey)
        d.synchronize()
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")
      UINotificationFeedbackGenerator().notificationOccurred(.error)
      return .result(dialog: IntentDialog(stringLiteral: "Copy failed — try again"))
    }

    // Clear green state after highlight window
    Task {
      try? await Task.sleep(nanoseconds: UInt64(copiedHighlightSeconds * 1_000_000_000) + 100_000_000)
      if let d = UserDefaults(suiteName: appGroupId) {
        if d.string(forKey: copiedIdKey) == id {
          d.removeObject(forKey: copiedIdKey)
          d.removeObject(forKey: copiedAtKey)
          d.synchronize()
          WidgetCenter.shared.reloadTimelines(ofKind: "ClipValWidget")
        }
      }
    }

    // System snippet at top of screen — unmistakable "I got your tap"
    return .result(dialog: IntentDialog(stringLiteral: "Copied — ready to paste"))
  }

  /// Load value for exactly this id from App Group (map → wv_ → JSON).
  private static func loadValue(for id: String) -> String? {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.synchronize()

    // 1) Atomic JSON map id → value
    if let mapData = defaults?.data(forKey: valuesMapKey),
       let obj = try? JSONSerialization.jsonObject(with: mapData) as? [String: Any],
       let v = obj[id] as? String,
       !v.isEmpty
    {
      return v
    }
    // map might be stored as [String:String] encoded
    if let mapData = defaults?.data(forKey: valuesMapKey),
       let map = try? JSONDecoder().decode([String: String].self, from: mapData),
       let v = map[id], !v.isEmpty
    {
      return v
    }

    // 2) Per-id key
    if let v = defaults?.string(forKey: "wv_\(id)"), !v.isEmpty {
      return v
    }

    // 3) Full snapshot JSON — match id exactly
    if let raw = defaults?.string(forKey: itemsKey) ?? {
      if let data = defaults?.data(forKey: itemsKey) {
        return String(data: data, encoding: .utf8)
      }
      return nil
    }(),
       let data = raw.data(using: .utf8),
       let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data),
       let item = payload.items.first(where: { $0.id == id }),
       !item.value.isEmpty
    {
      return item.value
    }

    // 4) Shared container file
    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId
    ) {
      let file = container.appendingPathComponent("widget_items.json")
      if let data = try? Data(contentsOf: file),
         let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data),
         let item = payload.items.first(where: { $0.id == id }),
         !item.value.isEmpty
      {
        return item.value
      }
    }

    return nil
  }
}

// Keep old name as typealias so any leftover refs compile (none expected)
@available(iOS 17.0, *)
typealias CopyValueIntent = CopyVaultItemIntent

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
      Image("ClipValMark")
        .resizable()
        .scaledToFill()
        .frame(width: 18, height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
      Text(entry.pinnedOnly ? "Favorites" : "ClipVal")
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .lineLimit(1)
      Spacer(minLength: 6)
      Text(entry.justCopiedId == nil
           ? (entry.pinnedOnly ? "Favorites" : "Recent · tap copy")
           : "✓ Copied — paste anywhere")
        .font(.system(size: 11, weight: entry.justCopiedId == nil ? .medium : .bold, design: .rounded))
        .foregroundStyle(entry.justCopiedId == nil ? .secondary : okGreen)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
  }

  private var emptyState: some View {
    // Teach: pin favorites → widget shows them. Link opens app.
    Link(destination: URL(string: "clipval://vault")!) {
      VStack(spacing: 8) {
        Image("ClipValMark")
          .resizable()
          .scaledToFill()
          .frame(width: 36, height: 36)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            .font(.system(size: metrics.checkSize * 1.15, weight: .heavy))
            .foregroundStyle(.white)
        } else {
          Text(item.displayMonogram)
            .font(.system(size: metrics.monoSize, weight: .bold, design: .rounded))
            .foregroundStyle(brand)
        }
      }
      .frame(width: metrics.monoFrame, height: metrics.monoFrame)
      .scaleEffect(hot ? 1.08 : 1.0)

      if hot {
        Text("Copied")
          .font(.system(size: max(metrics.titleSize, 11), weight: .bold, design: .rounded))
          .foregroundStyle(okGreen)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(maxWidth: .infinity)
        if !hideTitle {
          Text(shownTitle)
            .font(.system(size: max(metrics.titleSize - 1, 9), weight: .medium, design: .rounded))
            .foregroundStyle(okGreen.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
        }
      } else {
        Text(shownTitle)
          .font(.system(size: metrics.titleSize, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary)
          .lineLimit(metrics.titleLines)
          .minimumScaleFactor(0.6)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.vertical, metrics.padV)
    .padding(.horizontal, metrics.padH)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
        .fill(hot ? okGreen.opacity(colorScheme == .dark ? 0.28 : 0.18) : cellFill)
    )
    .overlay(
      RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
        .strokeBorder(hot ? okGreen : Color.primary.opacity(0.05), lineWidth: hot ? 2.5 : 1)
    )
    .contentShape(RoundedRectangle(cornerRadius: metrics.corner, style: .continuous))

    // In-widget copy — ONLY pass item id (value loaded from App Group by id).
    // Never pass value in the intent — that caused wrong-item copies.
    if #available(iOS 17.0, *) {
      return Button(intent: CopyVaultItemIntent(itemID: item.id)) {
        label
      }
      .buttonStyle(.plain)
    }
    // iOS 15–16 only
    return Link(destination: URL(string: "clipval://copy?id=\(item.id)")!) {
      label
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
