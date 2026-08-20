import UIKit

// MARK: - Shared keys (must match Flutter WidgetSnapshotService)

private let appGroupId = "group.com.clipval"
private let keyboardItemsKey = "keyboard_items_json"
private let widgetItemsKey = "widget_items_json"

/// ClipVal brand coral
private let brand = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1)
private let brandSoft = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 0.18)

// MARK: - Model

private struct KeyboardItem: Codable, Hashable {
  let id: String
  let title: String
  let value: String
  let monogram: String?
  let pinned: Bool?
  let sensitive: Bool?

  var isPinned: Bool { pinned == true }

  var displayTitle: String {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if !t.isEmpty { return t }
    let m = monogram?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return m.isEmpty ? "Item" : m
  }

  var monogramLetter: String {
    if let m = monogram?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty {
      return String(m.prefix(1)).uppercased()
    }
    let t = displayTitle
    return t.isEmpty ? "·" : String(t.prefix(1)).uppercased()
  }
}

private struct KeyboardPayload: Codable {
  let items: [KeyboardItem]
}

private enum KeyboardMode {
  case needsFullAccess
  case needsSync
  case ready
}

// MARK: - Controller

/// ClipVal keyboard — **grid tiles** (one-tap insert), privacy-first.
final class KeyboardViewController: UIInputViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  private var allItems: [KeyboardItem] = []
  private var mode: KeyboardMode = .needsFullAccess

  private let rootStack = UIStackView()
  private let brandLabel = UILabel()
  private let countLabel = UILabel()
  private var collection: UICollectionView!
  private let setupCard = UIView()
  private let setupIcon = UIImageView()
  private let setupTitle = UILabel()
  private let setupBody = UILabel()
  private let primaryButton = UIButton(type: .system)
  private let secondaryButton = UIButton(type: .system)
  private let toast = UILabel()
  private var gridHeight: NSLayoutConstraint!
  private var setupHeight: NSLayoutConstraint!
  private var searchExpanded = false
  private let searchField = UITextField()
  private var filter = ""

  override func viewDidLoad() {
    super.viewDidLoad()
    // Match system keyboard chrome (WhatsApp / dark or light)
    view.backgroundColor = .secondarySystemBackground
    buildUI()
    applyMode()
    reloadItems()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadItems()
  }

  override func textWillChange(_ textInput: UITextInput?) {}
  override func textDidChange(_ textInput: UITextInput?) {}

  // MARK: - Build

  private func buildUI() {
    rootStack.axis = .vertical
    rootStack.spacing = 0
    rootStack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      rootStack.topAnchor.constraint(equalTo: view.topAnchor),
      rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      view.heightAnchor.constraint(equalToConstant: 260),
    ])

    // Compact header: brand · count · search toggle · no fat search bar
    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8
    header.isLayoutMarginsRelativeArrangement = true
    header.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 4, right: 10)
    header.heightAnchor.constraint(equalToConstant: 34).isActive = true

    let mark = UIView()
    mark.backgroundColor = brand
    mark.layer.cornerRadius = 5
    mark.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      mark.widthAnchor.constraint(equalToConstant: 16),
      mark.heightAnchor.constraint(equalToConstant: 16),
    ])
    let markIcon = UIImageView(image: UIImage(systemName: "doc.on.clipboard.fill"))
    markIcon.tintColor = .white
    markIcon.contentMode = .scaleAspectFit
    markIcon.translatesAutoresizingMaskIntoConstraints = false
    mark.addSubview(markIcon)
    NSLayoutConstraint.activate([
      markIcon.centerXAnchor.constraint(equalTo: mark.centerXAnchor),
      markIcon.centerYAnchor.constraint(equalTo: mark.centerYAnchor),
      markIcon.widthAnchor.constraint(equalToConstant: 9),
      markIcon.heightAnchor.constraint(equalToConstant: 9),
    ])

    brandLabel.text = "ClipVal"
    brandLabel.font = .systemFont(ofSize: 14, weight: .bold)
    brandLabel.textColor = .label

    countLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    countLabel.textColor = .secondaryLabel

    let searchBtn = UIButton(type: .system)
    searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
    searchBtn.tintColor = .secondaryLabel
    searchBtn.addTarget(self, action: #selector(toggleSearch), for: .touchUpInside)
    searchBtn.accessibilityLabel = "Search"
    NSLayoutConstraint.activate([
      searchBtn.widthAnchor.constraint(equalToConstant: 32),
      searchBtn.heightAnchor.constraint(equalToConstant: 28),
    ])

    header.addArrangedSubview(mark)
    header.addArrangedSubview(brandLabel)
    header.addArrangedSubview(countLabel)
    header.addArrangedSubview(UIView()) // spacer
    header.addArrangedSubview(searchBtn)
    rootStack.addArrangedSubview(header)

    // Collapsible slim search (hidden by default — no fat bar)
    searchField.placeholder = "Filter…"
    searchField.font = .systemFont(ofSize: 14, weight: .regular)
    searchField.borderStyle = .none
    searchField.backgroundColor = .tertiarySystemFill
    searchField.layer.cornerRadius = 8
    searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
    searchField.leftViewMode = .always
    searchField.clearButtonMode = .whileEditing
    searchField.autocapitalizationType = .none
    searchField.autocorrectionType = .no
    searchField.returnKeyType = .done
    searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    searchField.delegate = self
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchField.heightAnchor.constraint(equalToConstant: 32).isActive = true
    let searchWrap = UIView()
    searchWrap.isHidden = true
    searchWrap.addSubview(searchField)
    NSLayoutConstraint.activate([
      searchField.leadingAnchor.constraint(equalTo: searchWrap.leadingAnchor, constant: 12),
      searchField.trailingAnchor.constraint(equalTo: searchWrap.trailingAnchor, constant: -12),
      searchField.topAnchor.constraint(equalTo: searchWrap.topAnchor, constant: 2),
      searchField.bottomAnchor.constraint(equalTo: searchWrap.bottomAnchor, constant: -4),
      searchWrap.heightAnchor.constraint(equalToConstant: 38),
    ])
    searchWrap.tag = 9001
    rootStack.addArrangedSubview(searchWrap)

    // —— GRID ——
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    layout.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.alwaysBounceVertical = true
    collection.showsVerticalScrollIndicator = false
    collection.register(TileCell.self, forCellWithReuseIdentifier: TileCell.reuseId)
    gridHeight = collection.heightAnchor.constraint(equalToConstant: 156)
    gridHeight.isActive = true
    rootStack.addArrangedSubview(collection)

    // Setup card
    setupCard.backgroundColor = .tertiarySystemBackground
    setupCard.layer.cornerRadius = 12
    setupHeight = setupCard.heightAnchor.constraint(equalToConstant: 168)
    setupHeight.isActive = true

    let setupStack = UIStackView()
    setupStack.axis = .vertical
    setupStack.spacing = 6
    setupStack.translatesAutoresizingMaskIntoConstraints = false
    setupCard.addSubview(setupStack)
    NSLayoutConstraint.activate([
      setupStack.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 14),
      setupStack.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -14),
      setupStack.topAnchor.constraint(equalTo: setupCard.topAnchor, constant: 12),
      setupStack.bottomAnchor.constraint(equalTo: setupCard.bottomAnchor, constant: -12),
    ])

    let topRow = UIStackView()
    topRow.axis = .horizontal
    topRow.spacing = 10
    topRow.alignment = .top
    setupIcon.tintColor = brand
    setupIcon.contentMode = .scaleAspectFit
    setupIcon.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      setupIcon.widthAnchor.constraint(equalToConstant: 24),
      setupIcon.heightAnchor.constraint(equalToConstant: 24),
    ])
    setupTitle.font = .systemFont(ofSize: 14, weight: .semibold)
    setupTitle.numberOfLines = 2
    setupBody.font = .systemFont(ofSize: 11, weight: .regular)
    setupBody.textColor = .secondaryLabel
    setupBody.numberOfLines = 4
    let textCol = UIStackView(arrangedSubviews: [setupTitle, setupBody])
    textCol.axis = .vertical
    textCol.spacing = 3
    topRow.addArrangedSubview(setupIcon)
    topRow.addArrangedSubview(textCol)
    setupStack.addArrangedSubview(topRow)

    primaryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    primaryButton.backgroundColor = brand
    primaryButton.setTitleColor(.white, for: .normal)
    primaryButton.layer.cornerRadius = 9
    primaryButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
    primaryButton.addTarget(self, action: #selector(tapPrimary), for: .touchUpInside)

    secondaryButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
    secondaryButton.setTitleColor(brand, for: .normal)
    secondaryButton.backgroundColor = brandSoft
    secondaryButton.layer.cornerRadius = 9
    secondaryButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
    secondaryButton.addTarget(self, action: #selector(tapSecondary), for: .touchUpInside)

    setupStack.addArrangedSubview(primaryButton)
    setupStack.addArrangedSubview(secondaryButton)

    let setupWrap = UIView()
    setupWrap.addSubview(setupCard)
    setupCard.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      setupCard.leadingAnchor.constraint(equalTo: setupWrap.leadingAnchor, constant: 12),
      setupCard.trailingAnchor.constraint(equalTo: setupWrap.trailingAnchor, constant: -12),
      setupCard.topAnchor.constraint(equalTo: setupWrap.topAnchor, constant: 2),
      setupCard.bottomAnchor.constraint(equalTo: setupWrap.bottomAnchor, constant: -2),
    ])
    rootStack.addArrangedSubview(setupWrap)

    // Slim toolbar: delete · open · globe
    let toolbar = UIStackView()
    toolbar.axis = .horizontal
    toolbar.spacing = 8
    toolbar.distribution = .fillEqually
    toolbar.isLayoutMarginsRelativeArrangement = true
    toolbar.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 2, right: 12)
    toolbar.addArrangedSubview(toolBtn(systemName: "delete.left", action: #selector(tapDelete)))
    toolbar.addArrangedSubview(toolBtn(title: "App", action: #selector(tapOpenApp)))
    toolbar.addArrangedSubview(toolBtn(systemName: "globe", action: #selector(tapNextKeyboard)))
    rootStack.addArrangedSubview(toolbar)

    toast.font = .systemFont(ofSize: 11, weight: .semibold)
    toast.textColor = brand
    toast.textAlignment = .center
    toast.numberOfLines = 2
    toast.alpha = 0
    toast.text = " "
    toast.heightAnchor.constraint(equalToConstant: 14).isActive = true
    rootStack.addArrangedSubview(toast)
  }

  private func toolBtn(title: String? = nil, systemName: String? = nil, action: Selector) -> UIButton {
    let b = UIButton(type: .system)
    if let systemName {
      b.setImage(UIImage(systemName: systemName), for: .normal)
      b.tintColor = .label
    } else {
      b.setTitle(title, for: .normal)
      b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
      b.setTitleColor(.label, for: .normal)
    }
    b.backgroundColor = .tertiarySystemFill
    b.layer.cornerRadius = 9
    b.heightAnchor.constraint(equalToConstant: 34).isActive = true
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  // MARK: - Mode

  private var searchWrap: UIView? {
    rootStack.arrangedSubviews.first { $0.tag == 9001 }
  }

  private func applyMode() {
    let ready = mode == .ready
    collection.isHidden = !ready
    setupCard.superview?.isHidden = ready
    gridHeight.constant = ready ? 156 : 0
    setupHeight.constant = ready ? 0 : 168

    // Never show fat empty search — only when expanded + ready + enough items
    let showSearch = ready && searchExpanded && allItems.count >= 6
    searchWrap?.isHidden = !showSearch
    if !showSearch {
      filter = ""
      searchField.text = nil
      searchField.resignFirstResponder()
    }

    switch mode {
    case .needsFullAccess:
      countLabel.text = "Setup"
      setupIcon.image = UIImage(systemName: "lock.open.fill")
      setupTitle.text = "Enable Full Access first"
      setupBody.text =
        "iOS blocks keyboard buttons until Full Access is on.\n"
        + "Settings → General → Keyboard → Keyboards → ClipVal → Allow Full Access\n"
        + "Then open ClipVal once."
      primaryButton.setTitle("I’ve enabled it — Refresh", for: .normal)
      primaryButton.tag = 1
      secondaryButton.setTitle("Why Full Access?", for: .normal)
      secondaryButton.isHidden = false
    case .needsSync:
      countLabel.text = "Sync"
      setupIcon.image = UIImage(systemName: "arrow.triangle.2.circlepath")
      setupTitle.text = "Open ClipVal once"
      setupBody.text = "Full Access is on. Open the app so vault tiles appear here."
      primaryButton.setTitle("Open ClipVal", for: .normal)
      primaryButton.tag = 2
      secondaryButton.setTitle("Refresh", for: .normal)
      secondaryButton.isHidden = false
    case .ready:
      let n = filteredItems.count
      countLabel.text = "\(n)"
      secondaryButton.isHidden = true
    }
  }

  private var filteredItems: [KeyboardItem] {
    let q = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if q.isEmpty { return allItems }
    return allItems.filter { $0.displayTitle.lowercased().contains(q) }
  }

  // MARK: - Data

  private func reloadItems() {
    if !hasFullAccess {
      mode = .needsFullAccess
      allItems = []
      applyMode()
      collection.reloadData()
      return
    }

    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.synchronize()
    let raw = Self.readString(defaults, keyboardItemsKey)
      ?? Self.readString(defaults, widgetItemsKey)

    guard let raw,
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(KeyboardPayload.self, from: data)
    else {
      mode = .needsSync
      allItems = []
      applyMode()
      collection.reloadData()
      return
    }

    allItems = payload.items
      .filter { ($0.sensitive != true) && !$0.value.isEmpty }
      .map { item in
        if let v = defaults?.string(forKey: "wv_\(item.id)"), !v.isEmpty {
          return KeyboardItem(
            id: item.id, title: item.title, value: v,
            monogram: item.monogram, pinned: item.pinned, sensitive: item.sensitive
          )
        }
        return item
      }
    allItems.sort { a, b in
      if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
      return a.displayTitle.localizedCaseInsensitiveCompare(b.displayTitle) == .orderedAscending
    }
    if allItems.count > 40 { allItems = Array(allItems.prefix(40)) }

    mode = allItems.isEmpty ? .needsSync : .ready
    applyMode()
    collection.reloadData()
  }

  private static func readString(_ defaults: UserDefaults?, _ key: String) -> String? {
    if let s = defaults?.string(forKey: key), !s.isEmpty { return s }
    if let d = defaults?.data(forKey: key), let s = String(data: d, encoding: .utf8), !s.isEmpty {
      return s
    }
    return nil
  }

  // MARK: - Actions

  @objc private func toggleSearch() {
    guard mode == .ready else { return }
    if allItems.count < 6 {
      flash("Search when you have 6+ items")
      return
    }
    searchExpanded.toggle()
    applyMode()
    if searchExpanded {
      searchField.becomeFirstResponder()
    }
  }

  @objc private func searchChanged() {
    filter = searchField.text ?? ""
    collection.reloadData()
    countLabel.text = "\(filteredItems.count)"
  }

  @objc private func tapPrimary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if primaryButton.tag == 1 {
      reloadItems()
      if mode == .needsFullAccess {
        flash("Still off — Settings → Keyboard → ClipVal → Full Access")
      } else if mode == .needsSync {
        flash("Full Access OK · open ClipVal once")
      } else {
        flash("Ready — tap a tile")
      }
    } else {
      openURL(URL(string: "clipval://vault")!) { ok in
        if !ok { self.flash("Open ClipVal from Home Screen") }
      }
    }
  }

  @objc private func tapSecondary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    switch mode {
    case .needsFullAccess:
      flash("Full Access = read on-device vault only. No keylogging. No network.")
    case .needsSync:
      reloadItems()
      flash(mode == .ready ? "Vault loaded" : "Still empty — open ClipVal")
    case .ready:
      break
    }
  }

  @objc private func tapDelete() {
    textDocumentProxy.deleteBackward()
  }

  @objc private func tapNextKeyboard() {
    advanceToNextInputMode()
  }

  @objc private func tapOpenApp() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if mode == .needsFullAccess {
      flash("Enable Full Access first — iOS blocks Open App")
      return
    }
    openURL(URL(string: "clipval://vault")!) { ok in
      if !ok { self.flash("Open ClipVal from Home Screen") }
    }
  }

  private func openURL(_ url: URL, completion: ((Bool) -> Void)? = nil) {
    var responder: UIResponder? = self
    let selOpen = sel_registerName("openURL:")
    while let r = responder {
      if r.responds(to: selOpen) {
        r.perform(selOpen, with: url)
        completion?(true)
        return
      }
      responder = r.next
    }
    if let ctx = extensionContext {
      ctx.open(url) { ok in
        DispatchQueue.main.async { completion?(ok) }
      }
      return
    }
    completion?(false)
  }

  private func insert(_ item: KeyboardItem) {
    guard !item.value.isEmpty else {
      flash("Empty — open ClipVal")
      return
    }
    textDocumentProxy.insertText(item.value)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    flash("✓ \(item.displayTitle)")
  }

  private func flash(_ text: String) {
    toast.text = text
    toast.alpha = 1
    UIView.animate(withDuration: 0.25, delay: 1.4, options: .curveEaseOut) {
      self.toast.alpha = 0
    }
  }

  // MARK: - Grid

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    filteredItems.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: TileCell.reuseId, for: indexPath
    ) as! TileCell
    cell.configure(filteredItems[indexPath.item])
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    insert(filteredItems[indexPath.item])
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let inset: CGFloat = 12
    let spacing: CGFloat = 8
    let cols: CGFloat = 3
    let w = collectionView.bounds.width - inset * 2 - spacing * (cols - 1)
    let cellW = floor(w / cols)
    return CGSize(width: max(cellW, 96), height: 64)
  }
}

// MARK: - Search field delegate

extension KeyboardViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

// MARK: - Tile cell (grid)

private final class TileCell: UICollectionViewCell {
  static let reuseId = "tile"
  private let monogram = UILabel()
  private let titleLabel = UILabel()
  private let pin = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .tertiarySystemBackground
    contentView.layer.cornerRadius = 12
    contentView.layer.cornerCurve = .continuous
    contentView.clipsToBounds = true

    monogram.font = .systemFont(ofSize: 13, weight: .bold)
    monogram.textColor = brand
    monogram.textAlignment = .center
    monogram.backgroundColor = brandSoft
    monogram.layer.cornerRadius = 10
    monogram.clipsToBounds = true
    monogram.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 2
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    pin.image = UIImage(systemName: "pin.fill")
    pin.tintColor = brand
    pin.contentMode = .scaleAspectFit
    pin.isHidden = true
    pin.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(monogram)
    contentView.addSubview(titleLabel)
    contentView.addSubview(pin)

    NSLayoutConstraint.activate([
      monogram.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      monogram.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      monogram.widthAnchor.constraint(equalToConstant: 22),
      monogram.heightAnchor.constraint(equalToConstant: 22),
      titleLabel.topAnchor.constraint(equalTo: monogram.bottomAnchor, constant: 4),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
      titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -6),
      pin.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
      pin.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
      pin.widthAnchor.constraint(equalToConstant: 9),
      pin.heightAnchor.constraint(equalToConstant: 9),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:)") }

  func configure(_ item: KeyboardItem) {
    monogram.text = item.monogramLetter
    titleLabel.text = item.displayTitle
    pin.isHidden = !item.isPinned
  }

  override var isHighlighted: Bool {
    didSet {
      contentView.alpha = isHighlighted ? 0.7 : 1
      contentView.transform = isHighlighted
        ? CGAffineTransform(scaleX: 0.96, y: 0.96)
        : .identity
    }
  }
}
