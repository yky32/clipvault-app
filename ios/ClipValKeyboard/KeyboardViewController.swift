import UIKit

// MARK: - Shared keys (must match Flutter WidgetSnapshotService)

private let appGroupId = "group.com.clipval"
private let keyboardItemsKey = "keyboard_items_json"
private let widgetItemsKey = "widget_items_json"

private let brand = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1)
private let brandSoft = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 0.18)

private let keyboardGridColsKey = "keyboard_grid_cols"

/// Grid density — user-toggled from header (persisted in App Group).
private enum GridLayout: Int, CaseIterable {
  case compact4 = 4   // dense
  case comfort3 = 3   // default-friendly
  case large2 = 2     // big tiles

  var next: GridLayout {
    switch self {
    case .compact4: return .comfort3
    case .comfort3: return .large2
    case .large2: return .compact4
    }
  }

  var symbolName: String {
    switch self {
    case .compact4: return "square.grid.3x3.fill"
    case .comfort3: return "square.grid.2x2.fill"
    case .large2: return "rectangle.grid.1x2.fill"
    }
  }

  var label: String {
    switch self {
    case .compact4: return "Dense · 4 columns"
    case .comfort3: return "Comfort · 3 columns"
    case .large2: return "Large · 2 columns"
    }
  }

  var rowsTarget: CGFloat {
    switch self {
    case .compact4: return 3
    case .comfort3: return 2.5
    case .large2: return 2
    }
  }
}

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
  private let layoutBtn = UIButton(type: .system)
  private let appBtn = UIButton(type: .system)
  private var gridLayout: GridLayout = .comfort3
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
    gridLayout = Self.loadGridLayout()
    buildUI()
    refreshLayoutButton()
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
    headerBar.isUserInteractionEnabled = true
    headerBar.clipsToBounds = false
    view.addSubview(headerBar)

    let mark = UIImageView(image: UIImage(named: "ClipValMark"))
    mark.contentMode = .scaleAspectFill
    mark.clipsToBounds = true
    mark.layer.cornerRadius = 4
    mark.translatesAutoresizingMaskIntoConstraints = false
    // Fallback if asset missing (dev)
    if mark.image == nil {
      mark.backgroundColor = brand
    }

    brandLabel.text = "ClipVal"
    brandLabel.font = .systemFont(ofSize: 13, weight: .bold)
    brandLabel.textColor = .label
    brandLabel.translatesAutoresizingMaskIntoConstraints = false

    countLabel.font = .systemFont(ofSize: 11, weight: .semibold)
    countLabel.textColor = .tertiaryLabel
    countLabel.translatesAutoresizingMaskIntoConstraints = false

    // Header actions: App · Search (globe lives on system bar below)
    appBtn.setImage(UIImage(systemName: "arrow.up.forward.app"), for: .normal)
    appBtn.tintColor = brand
    appBtn.backgroundColor = brandSoft
    appBtn.layer.cornerRadius = 6
    appBtn.accessibilityLabel = "Open ClipVal"
    appBtn.accessibilityHint = "Opens the ClipVal app"
    appBtn.isUserInteractionEnabled = true
    appBtn.addTarget(self, action: #selector(tapOpenApp), for: .touchUpInside)
    appBtn.translatesAutoresizingMaskIntoConstraints = false

    layoutBtn.tintColor = .secondaryLabel
    layoutBtn.accessibilityLabel = "Grid layout"
    layoutBtn.addTarget(self, action: #selector(cycleGridLayout), for: .touchUpInside)
    layoutBtn.translatesAutoresizingMaskIntoConstraints = false

    searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
    searchBtn.tintColor = .secondaryLabel
    searchBtn.addTarget(self, action: #selector(toggleSearch), for: .touchUpInside)
    searchBtn.translatesAutoresizingMaskIntoConstraints = false

    // Backspace lives in top-right action cluster (not bottom — frees grid)
    backspaceBtn.setImage(UIImage(systemName: "delete.left.fill"), for: .normal)
    backspaceBtn.tintColor = .label
    backspaceBtn.backgroundColor = .tertiarySystemFill
    backspaceBtn.layer.cornerRadius = 6
    backspaceBtn.accessibilityLabel = "Delete"
    backspaceBtn.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
    let longDel = UILongPressGestureRecognizer(target: self, action: #selector(backspaceLongPress(_:)))
    longDel.minimumPressDuration = 0.35
    backspaceBtn.addGestureRecognizer(longDel)
    backspaceBtn.translatesAutoresizingMaskIntoConstraints = false

    headerBar.addSubview(mark)
    headerBar.addSubview(brandLabel)
    headerBar.addSubview(countLabel)
    headerBar.addSubview(appBtn)
    headerBar.addSubview(layoutBtn)
    headerBar.addSubview(searchBtn)
    headerBar.addSubview(backspaceBtn)

    NSLayoutConstraint.activate([
      headerBar.topAnchor.constraint(equalTo: view.topAnchor),
      headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerBar.heightAnchor.constraint(equalToConstant: 34),

      mark.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
      mark.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      mark.widthAnchor.constraint(equalToConstant: 18),
      mark.heightAnchor.constraint(equalToConstant: 18),

      brandLabel.leadingAnchor.constraint(equalTo: mark.trailingAnchor, constant: 6),
      brandLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),

      countLabel.leadingAnchor.constraint(equalTo: brandLabel.trailingAnchor, constant: 6),
      countLabel.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),

      // Top-right actions (L→R): App · Layout · Search · ⌫
      // Rightmost = backspace (user request). Larger hit targets so App is tappable.
      backspaceBtn.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -6),
      backspaceBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      backspaceBtn.widthAnchor.constraint(equalToConstant: 36),
      backspaceBtn.heightAnchor.constraint(equalToConstant: 28),

      searchBtn.trailingAnchor.constraint(equalTo: backspaceBtn.leadingAnchor, constant: -4),
      searchBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      searchBtn.widthAnchor.constraint(equalToConstant: 32),
      searchBtn.heightAnchor.constraint(equalToConstant: 28),

      layoutBtn.trailingAnchor.constraint(equalTo: searchBtn.leadingAnchor, constant: -2),
      layoutBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      layoutBtn.widthAnchor.constraint(equalToConstant: 32),
      layoutBtn.heightAnchor.constraint(equalToConstant: 28),

      appBtn.trailingAnchor.constraint(equalTo: layoutBtn.leadingAnchor, constant: -2),
      appBtn.centerYAnchor.constraint(equalTo: headerBar.centerYAnchor),
      appBtn.widthAnchor.constraint(equalToConstant: 32),
      appBtn.heightAnchor.constraint(equalToConstant: 28),
    ])

    // Z-order: App must receive taps (not covered by siblings)
    headerBar.bringSubviewToFront(appBtn)
    headerBar.bringSubviewToFront(layoutBtn)
    headerBar.bringSubviewToFront(searchBtn)
    headerBar.bringSubviewToFront(backspaceBtn)

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

    // GRID fills to bottom (⌫ moved to header)
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
    collection.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
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
      collection.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),

      setupCard.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
      setupCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      setupCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      setupCard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),

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
      toast.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
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
    layoutBtn.isEnabled = ready
    layoutBtn.alpha = ready ? 1 : 0.35

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

  // MARK: - Grid layout

  private static func loadGridLayout() -> GridLayout {
    let defaults = UserDefaults(suiteName: appGroupId)
    let raw = defaults?.integer(forKey: keyboardGridColsKey) ?? 0
    return GridLayout(rawValue: raw) ?? .comfort3
  }

  private func saveGridLayout() {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(gridLayout.rawValue, forKey: keyboardGridColsKey)
    defaults?.synchronize()
  }

  private func refreshLayoutButton() {
    layoutBtn.setImage(UIImage(systemName: gridLayout.symbolName), for: .normal)
  }

  @objc private func cycleGridLayout() {
    guard mode == .ready else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    gridLayout = gridLayout.next
    saveGridLayout()
    refreshLayoutButton()
    collection.collectionViewLayout.invalidateLayout()
    collection.reloadData()
    flash(gridLayout.label)
  }

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
      self.openHostApp()
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
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    // Immediate feedback so tap never feels dead
    flash("Opening ClipVal…")
    openHostApp()
  }

  /// Open main ClipVal app. Prefer extensionContext; never fake success.
  private func openHostApp() {
    // clipval://vault → scheme clipval, host vault (handled by GoRouter → /vault)
    let urls = [
      URL(string: "clipval://vault")!,
      URL(string: "clipval://")!,
    ]
    openURL(urls[0]) { [weak self] ok in
      guard let self else { return }
      if ok { return }
      // Second candidate
      self.openURL(urls[1]) { ok2 in
        if !ok2 {
          if !self.hasFullAccess {
            self.flash("Enable Full Access, or open ClipVal from Home")
          } else {
            self.flash("Couldn’t open — tap ClipVal on Home Screen")
          }
        }
      }
    }
  }

  private func openURL(_ url: URL, completion: ((Bool) -> Void)? = nil) {
    // 1) Official path for app extensions (keyboard needs RequestsOpenAccess / Full Access)
    if let ctx = self.extensionContext {
      ctx.open(url) { ok in
        DispatchQueue.main.async {
          if ok {
            completion?(true)
            return
          }
          // 2) Responder-chain fallback (do NOT assume success)
          self.openURLViaResponderChain(url, completion: completion)
        }
      }
      return
    }
    openURLViaResponderChain(url, completion: completion)
  }

  private func openURLViaResponderChain(_ url: URL, completion: ((Bool) -> Void)?) {
    var responder: UIResponder? = self as UIResponder
    // Prefer modern openURL:options:completionHandler: if exposed on a responder
    let modern = sel_registerName("openURL:options:completionHandler:")
    let legacy = sel_registerName("openURL:")

    while let r = responder {
      if r.responds(to: modern) {
        // application.open(url, options:completionHandler:)
        typealias OpenModern = @convention(c) (AnyObject, Selector, URL, NSDictionary, ((Bool) -> Void)?) -> Void
        let imp = r.method(for: modern)
        let fn = unsafeBitCast(imp, to: OpenModern.self)
        fn(r, modern, url, [:], { ok in
          DispatchQueue.main.async { completion?(ok) }
        })
        return
      }
      responder = r.next
    }

    responder = self as UIResponder
    while let r = responder {
      if r.responds(to: legacy) {
        r.perform(legacy, with: url)
        // Legacy has no completion — unknown outcome. Report false so UI can guide user
        // if app didn't come forward (better than silent fake success).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
          // If we're still visible as keyboard, open likely failed.
          completion?(false)
        }
        return
      }
      responder = r.next
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
    let cols = CGFloat(gridLayout.rawValue)
    let inset: CGFloat = 8
    let spacing: CGFloat = gridLayout == .large2 ? 6 : 5
    let usable = collectionView.bounds.width - inset * 2 - spacing * (cols - 1)
    let w = floor(usable / cols)

    let rowsTarget = gridLayout.rowsTarget
    let vSpacing: CGFloat = spacing
    let vInset: CGFloat = 4
    let h = collectionView.bounds.height
    let cellH: CGFloat
    if h > 40 {
      cellH = floor((h - vInset - vSpacing * max(rowsTarget - 1, 1)) / rowsTarget)
    } else {
      cellH = 52
    }
    let minH: CGFloat = gridLayout == .large2 ? 56 : 48
    let maxH: CGFloat = gridLayout == .large2 ? 88 : 72
    let minW: CGFloat = gridLayout == .compact4 ? 68 : 80
    return CGSize(width: max(w, minW), height: max(min(cellH, maxH), minH))
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
