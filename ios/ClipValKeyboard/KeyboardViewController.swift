import UIKit

// MARK: - Shared keys (must match Flutter WidgetSnapshotService)

private let appGroupId = "group.com.clipval"
private let keyboardItemsKey = "keyboard_items_json"
private let widgetItemsKey = "widget_items_json"

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

/// Dense grid keyboard — chrome minimal, tiles fill the rest.
final class KeyboardViewController: UIInputViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
  private var allItems: [KeyboardItem] = []
  private var mode: KeyboardMode = .needsFullAccess
  private var filter = ""
  private var searchExpanded = false

  private let headerBar = UIView()
  private let brandLabel = UILabel()
  private let countLabel = UILabel()
  private let searchBtn = UIButton(type: .system)
  private let appBtn = UIButton(type: .system)
  private let searchField = UITextField()
  private let searchBar = UIView()
  private var collection: UICollectionView!
  private let setupCard = UIView()
  private let setupIcon = UIImageView()
  private let setupTitle = UILabel()
  private let setupBody = UILabel()
  private let primaryButton = UIButton(type: .system)
  private let secondaryButton = UIButton(type: .system)
  private let backspaceBtn = UIButton(type: .system)
  private let toast = UILabel()

  private var searchBarHeight: NSLayoutConstraint!
  private var keyboardHeight: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .secondarySystemBackground
    buildUI()
    applyMode()
    reloadItems()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadItems()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collection?.collectionViewLayout.invalidateLayout()
  }

  override func textWillChange(_ textInput: UITextInput?) {}
  override func textDidChange(_ textInput: UITextInput?) {}

  // MARK: - Build (header + fill-middle grid + slim toolbar)

  private func buildUI() {
    // Overall keyboard taller so grid can show ~3 rows
    keyboardHeight = view.heightAnchor.constraint(equalToConstant: 292)
    keyboardHeight.isActive = true

    // Header 28pt
    headerBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBar)

    let mark = UIView()
    mark.backgroundColor = brand
    mark.layer.cornerRadius = 4
    mark.translatesAutoresizingMaskIntoConstraints = false
    let markIcon = UIImageView(image: UIImage(systemName: "doc.on.clipboard.fill"))
    markIcon.tintColor = .white
    markIcon.contentMode = .scaleAspectFit
    markIcon.translatesAutoresizingMaskIntoConstraints = false
    mark.addSubview(markIcon)

    brandLabel.text = "ClipVal"
    brandLabel.font = .systemFont(ofSize: 13, weight: .bold)
    brandLabel.textColor = .label
    brandLabel.translatesAutoresizingMaskIntoConstraints = false

    countLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    countLabel.textColor = .tertiaryLabel
    countLabel.translatesAutoresizingMaskIntoConstraints = false

    // Header actions: App · Search (globe lives on system bar below)
    appBtn.setImage(UIImage(systemName: "arrow.up.forward.app"), for: .normal)
    appBtn.tintColor = .secondaryLabel
    appBtn.accessibilityLabel = "Open ClipVal"
    appBtn.addTarget(self, action: #selector(tapOpenApp), for: .touchUpInside)
    appBtn.translatesAutoresizingMaskIntoConstraints = false

    searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
    searchBtn.tintColor = .secondaryLabel
    searchBtn.addTarget(self, action: #selector(toggleSearch), for: .touchUpInside)
    searchBtn.translatesAutoresizingMaskIntoConstraints = false

    headerBar.addSubview(mark)
    headerBar.addSubview(brandLabel)
    headerBar.addSubview(countLabel)
    headerBar.addSubview(appBtn)
    headerBar.addSubview(searchBtn)

    NSLayoutConstraint.activate([
      headerBar.topAnchor.constraint(equalTo: view.topAnchor),
      headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerBar.heightAnchor.constraint(equalToConstant: 28),

      mark.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
      mark.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      mark.widthAnchor.constraint(equalToConstant: 14),
      mark.heightAnchor.constraint(equalToConstant: 14),
      markIcon.centerXAnchor.constraint(equalTo: mark.centerXAnchor),
      markIcon.centerYAnchor.constraint(equalTo: mark.centerYAnchor),
      markIcon.widthAnchor.constraint(equalToConstant: 8),
      markIcon.heightAnchor.constraint(equalToConstant: 8),

      brandLabel.leadingAnchor.constraint(equalTo: mark.trailingAnchor, constant: 6),
      brandLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),

      countLabel.leadingAnchor.constraint(equalTo: brandLabel.trailingAnchor, constant: 6),
      countLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),

      searchBtn.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -4),
      searchBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      searchBtn.widthAnchor.constraint(equalToConstant: 28),
      searchBtn.heightAnchor.constraint(equalToConstant: 26),

      appBtn.trailingAnchor.constraint(equalTo: searchBtn.leadingAnchor, constant: -2),
      appBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      appBtn.widthAnchor.constraint(equalToConstant: 28),
      appBtn.heightAnchor.constraint(equalToConstant: 26),
    ])

    // Search bar (collapsed height 0)
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.clipsToBounds = true
    view.addSubview(searchBar)
    searchBarHeight = searchBar.heightAnchor.constraint(equalToConstant: 0)
    searchBarHeight.isActive = true

    searchField.placeholder = "Filter…"
    searchField.font = .systemFont(ofSize: 13)
    searchField.backgroundColor = .tertiarySystemFill
    searchField.layer.cornerRadius = 8
    searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
    searchField.leftViewMode = .always
    searchField.clearButtonMode = .whileEditing
    searchField.autocapitalizationType = .none
    searchField.autocorrectionType = .no
    searchField.returnKeyType = .done
    searchField.delegate = self
    searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchBar.addSubview(searchField)
    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
      searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      searchField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 10),
      searchField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -10),
      searchField.topAnchor.constraint(equalTo: searchBar.topAnchor, constant: 2),
      searchField.heightAnchor.constraint(equalToConstant: 28),
    ])

    // Bottom-right backspace only (system globe below; App in header)
    backspaceBtn.setImage(UIImage(systemName: "delete.left.fill"), for: .normal)
    backspaceBtn.tintColor = .label
    backspaceBtn.backgroundColor = .tertiarySystemFill
    backspaceBtn.layer.cornerRadius = 8
    backspaceBtn.accessibilityLabel = "Delete"
    backspaceBtn.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
    // Long-press = repeat delete
    let longDel = UILongPressGestureRecognizer(target: self, action: #selector(backspaceLongPress(_:)))
    longDel.minimumPressDuration = 0.35
    backspaceBtn.addGestureRecognizer(longDel)
    backspaceBtn.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(backspaceBtn)
    NSLayoutConstraint.activate([
      backspaceBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      backspaceBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
      backspaceBtn.widthAnchor.constraint(equalToConstant: 72),
      backspaceBtn.heightAnchor.constraint(equalToConstant: 34),
    ])

    // GRID fills everything between search and toolbar
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 5
    layout.minimumLineSpacing = 5
    layout.sectionInset = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)

    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.alwaysBounceVertical = true
    collection.showsVerticalScrollIndicator = false
    collection.contentInsetAdjustmentBehavior = .never
    // Keep last row clear of bottom-right backspace
    collection.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 2, right: 0)
    collection.register(TileCell.self, forCellWithReuseIdentifier: TileCell.reuseId)
    collection.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collection)

    // Setup overlay (same region as grid)
    setupCard.translatesAutoresizingMaskIntoConstraints = false
    setupCard.backgroundColor = .tertiarySystemBackground
    setupCard.layer.cornerRadius = 12
    setupCard.isHidden = true
    view.addSubview(setupCard)

    setupIcon.tintColor = brand
    setupIcon.contentMode = .scaleAspectFit
    setupIcon.translatesAutoresizingMaskIntoConstraints = false
    setupTitle.font = .systemFont(ofSize: 13, weight: .semibold)
    setupTitle.numberOfLines = 2
    setupTitle.translatesAutoresizingMaskIntoConstraints = false
    setupBody.font = .systemFont(ofSize: 11)
    setupBody.textColor = .secondaryLabel
    setupBody.numberOfLines = 0
    setupBody.translatesAutoresizingMaskIntoConstraints = false
    primaryButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
    primaryButton.backgroundColor = brand
    primaryButton.setTitleColor(.white, for: .normal)
    primaryButton.layer.cornerRadius = 8
    primaryButton.translatesAutoresizingMaskIntoConstraints = false
    primaryButton.addTarget(self, action: #selector(tapPrimary), for: .touchUpInside)
    secondaryButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
    secondaryButton.setTitleColor(brand, for: .normal)
    secondaryButton.backgroundColor = brandSoft
    secondaryButton.layer.cornerRadius = 8
    secondaryButton.translatesAutoresizingMaskIntoConstraints = false
    secondaryButton.addTarget(self, action: #selector(tapSecondary), for: .touchUpInside)

    setupCard.addSubview(setupIcon)
    setupCard.addSubview(setupTitle)
    setupCard.addSubview(setupBody)
    setupCard.addSubview(primaryButton)
    setupCard.addSubview(secondaryButton)

    NSLayoutConstraint.activate([
      collection.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 2),
      collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      // Leave room for bottom-right backspace only
      collection.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -42),

      setupCard.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
      setupCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      setupCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      setupCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -42),

      setupIcon.topAnchor.constraint(equalTo: setupCard.topAnchor, constant: 12),
      setupIcon.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 12),
      setupIcon.widthAnchor.constraint(equalToConstant: 22),
      setupIcon.heightAnchor.constraint(equalToConstant: 22),

      setupTitle.topAnchor.constraint(equalTo: setupCard.topAnchor, constant: 12),
      setupTitle.leadingAnchor.constraint(equalTo: setupIcon.trailingAnchor, constant: 8),
      setupTitle.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -12),

      setupBody.topAnchor.constraint(equalTo: setupTitle.bottomAnchor, constant: 4),
      setupBody.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 12),
      setupBody.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -12),

      primaryButton.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 12),
      primaryButton.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -12),
      primaryButton.heightAnchor.constraint(equalToConstant: 34),
      primaryButton.bottomAnchor.constraint(equalTo: secondaryButton.topAnchor, constant: -6),

      secondaryButton.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 12),
      secondaryButton.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -12),
      secondaryButton.heightAnchor.constraint(equalToConstant: 30),
      secondaryButton.bottomAnchor.constraint(equalTo: setupCard.bottomAnchor, constant: -12),
    ])

    // Toast overlay on grid
    toast.font = .systemFont(ofSize: 11, weight: .semibold)
    toast.textColor = .white
    toast.backgroundColor = brand.withAlphaComponent(0.92)
    toast.textAlignment = .center
    toast.layer.cornerRadius = 8
    toast.clipsToBounds = true
    toast.alpha = 0
    toast.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toast)
    NSLayoutConstraint.activate([
      toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toast.bottomAnchor.constraint(equalTo: backspaceBtn.topAnchor, constant: -8),
      toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
      toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 26),
    ])
    toast.setContentHuggingPriority(.required, for: .vertical)
  }


  // MARK: - Mode

  private func applyMode() {
    let ready = mode == .ready
    collection.isHidden = !ready
    setupCard.isHidden = ready
    searchBtn.isEnabled = ready

    let showSearch = ready && searchExpanded && allItems.count >= 6
    searchBarHeight.constant = showSearch ? 34 : 0
    searchBar.isHidden = !showSearch
    if !showSearch {
      filter = ""
      searchField.text = nil
      searchField.resignFirstResponder()
    }

    switch mode {
    case .needsFullAccess:
      countLabel.text = ""
      setupIcon.image = UIImage(systemName: "lock.open.fill")
      setupTitle.text = "Enable Full Access first"
      setupBody.text =
        "Settings → General → Keyboard → Keyboards → ClipVal → Allow Full Access.\nThen open ClipVal once. (iOS blocks buttons here until then.)"
      primaryButton.setTitle("I’ve enabled it — Refresh", for: .normal)
      primaryButton.tag = 1
      secondaryButton.setTitle("Why Full Access?", for: .normal)
      secondaryButton.isHidden = false
    case .needsSync:
      countLabel.text = ""
      setupIcon.image = UIImage(systemName: "arrow.triangle.2.circlepath")
      setupTitle.text = "Open ClipVal once"
      setupBody.text = "Full Access is on. Open the app so vault tiles fill this grid."
      primaryButton.setTitle("Open ClipVal", for: .normal)
      primaryButton.tag = 2
      secondaryButton.setTitle("Refresh", for: .normal)
      secondaryButton.isHidden = false
    case .ready:
      countLabel.text = "\(filteredItems.count)"
      secondaryButton.isHidden = true
    }

    UIView.animate(withDuration: 0.15) { self.view.layoutIfNeeded() }
    collection.collectionViewLayout.invalidateLayout()
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
    if allItems.count > 48 { allItems = Array(allItems.prefix(48)) }

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
      flash("Search when 6+ items")
      return
    }
    searchExpanded.toggle()
    applyMode()
    if searchExpanded { searchField.becomeFirstResponder() }
  }

  @objc private func searchChanged() {
    filter = searchField.text ?? ""
    countLabel.text = "\(filteredItems.count)"
    collection.reloadData()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  @objc private func tapPrimary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if primaryButton.tag == 1 {
      reloadItems()
      if mode == .needsFullAccess {
        flash("Still off — Settings → Keyboard → ClipVal")
      } else if mode == .needsSync {
        flash("Open ClipVal once")
      } else {
        flash("Ready")
      }
    } else {
      openURL(URL(string: "clipval://vault")!) { ok in
        if !ok { self.flash("Open ClipVal from Home") }
      }
    }
  }

  @objc private func tapSecondary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    switch mode {
    case .needsFullAccess:
      flash("On-device vault only · no keylogging · no network")
    case .needsSync:
      reloadItems()
      flash(mode == .ready ? "Loaded" : "Open ClipVal app")
    case .ready:
      break
    }
  }

  @objc private func tapDelete() { textDocumentProxy.deleteBackward() }

  private var deleteTimer: Timer?

  @objc private func backspaceLongPress(_ g: UILongPressGestureRecognizer) {
    switch g.state {
    case .began:
      deleteTimer?.invalidate()
      deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
        self?.textDocumentProxy.deleteBackward()
      }
      if let t = deleteTimer { RunLoop.main.add(t, forMode: .common) }
    case .ended, .cancelled, .failed:
      deleteTimer?.invalidate()
      deleteTimer = nil
    default:
      break
    }
  }

  @objc private func tapOpenApp() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if mode == .needsFullAccess {
      flash("Enable Full Access first")
      return
    }
    openURL(URL(string: "clipval://vault")!) { ok in
      if !ok { self.flash("Open ClipVal from Home") }
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
      ctx.open(url) { ok in DispatchQueue.main.async { completion?(ok) } }
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
    toast.text = "  \(text)  "
    toast.alpha = 1
    UIView.animate(withDuration: 0.2, delay: 1.2, options: .curveEaseOut) {
      self.toast.alpha = 0
    }
  }

  // MARK: - Grid (4 cols, short tiles — fill height)

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
    let cols: CGFloat = 4
    let inset: CGFloat = 8
    let spacing: CGFloat = 5
    let usable = collectionView.bounds.width - inset * 2 - spacing * (cols - 1)
    let w = floor(usable / cols)

    // Fit as many rows as possible in available height
    let rowsTarget: CGFloat = 3
    let vSpacing: CGFloat = 5
    let vInset: CGFloat = 4
    let h = collectionView.bounds.height
    let cellH: CGFloat
    if h > 40 {
      cellH = floor((h - vInset - vSpacing * (rowsTarget - 1)) / rowsTarget)
    } else {
      cellH = 52
    }
    return CGSize(width: max(w, 72), height: max(min(cellH, 72), 48))
  }
}

// MARK: - Compact tile

private final class TileCell: UICollectionViewCell {
  static let reuseId = "tile"
  private let monogram = UILabel()
  private let titleLabel = UILabel()
  private let pin = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .tertiarySystemBackground
    contentView.layer.cornerRadius = 10
    contentView.layer.cornerCurve = .continuous
    contentView.clipsToBounds = true

    monogram.font = .systemFont(ofSize: 11, weight: .bold)
    monogram.textColor = brand
    monogram.textAlignment = .center
    monogram.backgroundColor = brandSoft
    monogram.layer.cornerRadius = 8
    monogram.clipsToBounds = true
    monogram.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
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
      monogram.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      monogram.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      monogram.widthAnchor.constraint(equalToConstant: 18),
      monogram.heightAnchor.constraint(equalToConstant: 18),

      titleLabel.topAnchor.constraint(equalTo: monogram.bottomAnchor, constant: 3),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
      titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4),

      pin.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      pin.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
      pin.widthAnchor.constraint(equalToConstant: 8),
      pin.heightAnchor.constraint(equalToConstant: 8),
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
      UIView.animate(withDuration: 0.08) {
        self.contentView.alpha = self.isHighlighted ? 0.65 : 1
        self.contentView.transform = self.isHighlighted
          ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
      }
    }
  }
}
