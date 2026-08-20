import UIKit

// MARK: - App Group (same as Widget / Share)

private let appGroupId = "group.com.clipval"
/// Dedicated keyboard payload (fallback: widget snapshot).
private let keyboardItemsKey = "keyboard_items_json"
private let widgetItemsKey = "widget_items_json"
private let brand = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1)

private struct KeyboardItem: Codable, Hashable {
  let id: String
  let title: String
  let value: String
  let monogram: String?
  let pinned: Bool?
  let sensitive: Bool?

  var isSensitive: Bool { sensitive == true }
  var isPinned: Bool { pinned == true }

  var displayTitle: String {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if !t.isEmpty { return t }
    let m = monogram?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !m.isEmpty { return m }
    return "···"
  }
}

private struct KeyboardPayload: Codable {
  let items: [KeyboardItem]
}

/// Custom keyboard: one-tap insert from vault (CopyNow-class UX, privacy-first).
///
/// Apple-risk posture:
/// - No URLSession / no network
/// - No keystroke logging
/// - Sensitive items never listed
/// - Full Access only for App Group read (disclosed in Settings)
/// - Globe always available
final class KeyboardViewController: UIInputViewController, UISearchBarDelegate {
  private var allItems: [KeyboardItem] = []
  private var visible: [KeyboardItem] = []
  private var collection: UICollectionView!
  private var emptyLabel: UILabel!
  private var statusLabel: UILabel!
  private var searchBar: UISearchBar!
  private var filter: String = ""
  private var toastLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .secondarySystemBackground
    buildChrome()
    reloadItems()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadItems()
  }

  override func textWillChange(_ textInput: UITextInput?) {}
  override func textDidChange(_ textInput: UITextInput?) {}

  // MARK: - UI

  private func buildChrome() {
    let root = UIStackView()
    root.axis = .vertical
    root.spacing = 6
    root.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(root)

    NSLayoutConstraint.activate([
      root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
      root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
      view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280),
    ])

    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8

    let title = UILabel()
    title.text = "ClipVal"
    title.font = .systemFont(ofSize: 16, weight: .bold)
    title.textColor = brand

    statusLabel = UILabel()
    statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .right
    statusLabel.numberOfLines = 2

    header.addArrangedSubview(title)
    header.addArrangedSubview(statusLabel)
    root.addArrangedSubview(header)

    searchBar = UISearchBar(frame: .zero)
    searchBar.searchBarStyle = .minimal
    searchBar.placeholder = "Search vault…"
    searchBar.delegate = self
    searchBar.autocapitalizationType = .none
    searchBar.autocorrectionType = .no
    searchBar.enablesReturnKeyAutomatically = true
    searchBar.returnKeyType = .search
    searchBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
    root.addArrangedSubview(searchBar)

    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 6
    layout.minimumLineSpacing = 6
    layout.sectionInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.keyboardDismissMode = .onDrag
    collection.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.reuseId)
    collection.register(
      SectionHeader.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: SectionHeader.reuseId
    )
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.heightAnchor.constraint(equalToConstant: 168).isActive = true
    root.addArrangedSubview(collection)

    emptyLabel = UILabel()
    emptyLabel.textAlignment = .center
    emptyLabel.numberOfLines = 0
    emptyLabel.font = .systemFont(ofSize: 13)
    emptyLabel.textColor = .secondaryLabel
    emptyLabel.isHidden = true
    root.addArrangedSubview(emptyLabel)

    let bar = UIStackView()
    bar.axis = .horizontal
    bar.spacing = 8
    bar.distribution = .fillEqually
    bar.addArrangedSubview(makeBarButton(title: "⌫", action: #selector(tapDelete)))
    bar.addArrangedSubview(makeBarButton(title: "Open App", action: #selector(tapOpenApp)))
    bar.addArrangedSubview(makeBarButton(title: "🌐", action: #selector(tapNextKeyboard)))
    root.addArrangedSubview(bar)

    toastLabel = UILabel()
    toastLabel.textAlignment = .center
    toastLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    toastLabel.textColor = brand
    toastLabel.text = " "
    toastLabel.alpha = 0
    root.addArrangedSubview(toastLabel)

    let foot = UILabel()
    foot.text = "Private vault · No keylogging · Sensitive hidden"
    foot.font = .systemFont(ofSize: 10, weight: .medium)
    foot.textColor = .tertiaryLabel
    foot.textAlignment = .center
    root.addArrangedSubview(foot)
  }

  private func makeBarButton(title: String, action: Selector) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    b.backgroundColor = .tertiarySystemFill
    b.layer.cornerRadius = 8
    b.heightAnchor.constraint(equalToConstant: 40).isActive = true
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  // MARK: - Data

  private func reloadItems() {
    guard hasFullAccess else {
      allItems = []
      applyFilter()
      statusLabel.text = "Allow Full Access"
      emptyLabel.isHidden = false
      emptyLabel.text =
        "Apple requires Full Access so this keyboard can read your on-device ClipVal snapshot (not the internet).\n\n"
        + "Settings → General → Keyboard → Keyboards → ClipVal → Allow Full Access.\n\n"
        + "ClipVal never logs keys and has no network in the keyboard."
      return
    }

    let defaults = UserDefaults(suiteName: appGroupId)
    let raw = defaults?.string(forKey: keyboardItemsKey)
      ?? defaults?.string(forKey: widgetItemsKey)

    guard let raw,
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(KeyboardPayload.self, from: data)
    else {
      allItems = []
      applyFilter()
      statusLabel.text = "Open ClipVal once"
      emptyLabel.isHidden = false
      emptyLabel.text =
        "No vault snapshot yet.\nOpen ClipVal so pinned & recent items sync to the keyboard."
      return
    }

    // Never show sensitive values on the keyboard surface.
    allItems = payload.items.filter { !$0.isSensitive && !$0.value.isEmpty }
    if allItems.count > 32 {
      allItems = Array(allItems.prefix(32))
    }
    applyFilter()
  }

  private func applyFilter() {
    let q = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if q.isEmpty {
      visible = allItems
    } else {
      visible = allItems.filter { $0.displayTitle.lowercased().contains(q) }
    }
    let pinN = visible.filter(\.isPinned).count
    statusLabel.text = visible.isEmpty
      ? "No matches"
      : "\(visible.count) · tap insert\(pinN > 0 ? " · \(pinN) pinned" : "")"
    emptyLabel.isHidden = !visible.isEmpty
    if visible.isEmpty && !allItems.isEmpty {
      emptyLabel.text = "No titles match “\(filter)”."
    } else if visible.isEmpty {
      emptyLabel.text = "Pin items or copy once in ClipVal.\nSensitive items never appear here."
    }
    collection.reloadData()
  }

  private var pinnedItems: [KeyboardItem] { visible.filter(\.isPinned) }
  private var otherItems: [KeyboardItem] { visible.filter { !$0.isPinned } }

  private func item(at indexPath: IndexPath) -> KeyboardItem {
    if pinnedItems.isEmpty { return visible[indexPath.item] }
    if indexPath.section == 0 { return pinnedItems[indexPath.item] }
    return otherItems[indexPath.item]
  }

  // MARK: - Actions

  @objc private func tapDelete() { textDocumentProxy.deleteBackward() }
  @objc private func tapNextKeyboard() { advanceToNextInputMode() }

  @objc private func tapOpenApp() {
    guard let url = URL(string: "clipval://") else { return }
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        app.open(url, options: [:], completionHandler: nil)
        return
      }
      if r.responds(to: Selector(("openURL:"))) {
        r.perform(Selector(("openURL:")), with: url)
        return
      }
      responder = r.next
    }
    extensionContext?.open(url, completionHandler: nil)
  }

  private func insert(_ item: KeyboardItem) {
    guard !item.value.isEmpty else { return }
    textDocumentProxy.insertText(item.value)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    flashToast("Inserted · \(item.displayTitle)")
  }

  private func flashToast(_ text: String) {
    toastLabel.text = text
    toastLabel.alpha = 1
    UIView.animate(withDuration: 0.25, delay: 0.9, options: .curveEaseOut) {
      self.toastLabel.alpha = 0
    }
  }

  // MARK: - Search

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    filter = searchText
    applyFilter()
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}

// MARK: - Collection

extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    if pinnedItems.isEmpty { return 1 }
    return otherItems.isEmpty ? 1 : 2
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if pinnedItems.isEmpty { return visible.count }
    return section == 0 ? pinnedItems.count : otherItems.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ChipCell.reuseId,
      for: indexPath
    ) as! ChipCell
    let it = item(at: indexPath)
    cell.configure(title: it.displayTitle, pinned: it.isPinned)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    insert(item(at: indexPath))
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: SectionHeader.reuseId,
      for: indexPath
    ) as! SectionHeader
    if pinnedItems.isEmpty {
      header.configure(title: "VAULT")
    } else if indexPath.section == 0 {
      header.configure(title: "PINNED")
    } else {
      header.configure(title: "RECENT")
    }
    return header
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    referenceSizeForHeaderInSection section: Int
  ) -> CGSize {
    CGSize(width: collectionView.bounds.width, height: 18)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let w = collectionView.bounds.width
    let cols: CGFloat = w > 420 ? 3 : 2
    let spacing: CGFloat = 6
    let width = floor((w - spacing * (cols - 1)) / cols)
    return CGSize(width: max(width, 96), height: 38)
  }
}

// MARK: - Cells

private final class SectionHeader: UICollectionReusableView {
  static let reuseId = "section"
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    label.font = .systemFont(ofSize: 10, weight: .semibold)
    label.textColor = .tertiaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:)") }
  func configure(title: String) { label.text = title }
}

private final class ChipCell: UICollectionViewCell {
  static let reuseId = "chip"
  private let label = UILabel()
  private let pin = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .tertiarySystemBackground
    contentView.layer.cornerRadius = 10
    contentView.layer.borderWidth = 1
    contentView.layer.borderColor = UIColor.separator.cgColor

    label.font = .systemFont(ofSize: 14, weight: .semibold)
    label.textColor = .label
    label.lineBreakMode = .byTruncatingTail
    label.translatesAutoresizingMaskIntoConstraints = false

    pin.font = .systemFont(ofSize: 10)
    pin.text = "📌"
    pin.translatesAutoresizingMaskIntoConstraints = false
    pin.isHidden = true

    contentView.addSubview(label)
    contentView.addSubview(pin)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
      label.trailingAnchor.constraint(equalTo: pin.leadingAnchor, constant: -4),
      label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      pin.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
      pin.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:)") }

  func configure(title: String, pinned: Bool) {
    label.text = title
    pin.isHidden = !pinned
  }

  override var isHighlighted: Bool {
    didSet {
      contentView.backgroundColor = isHighlighted
        ? brand.withAlphaComponent(0.18)
        : .tertiarySystemBackground
    }
  }

  private var brand: UIColor { UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1) }
}
