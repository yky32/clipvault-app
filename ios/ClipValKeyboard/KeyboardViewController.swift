import UIKit

// MARK: - Shared keys (must match Flutter WidgetSnapshotService)

private let appGroupId = "group.com.clipval"
private let keyboardItemsKey = "keyboard_items_json"
private let widgetItemsKey = "widget_items_json"

/// ClipVal brand coral (aligned with app primary).
private let brand = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1)
private let brandSoft = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 0.14)

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

/// Professional vault keyboard — dense list, clear setup, privacy-first.
final class KeyboardViewController: UIInputViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
  private var allItems: [KeyboardItem] = []
  private var visible: [KeyboardItem] = []
  private var filter = ""
  private var mode: KeyboardMode = .needsFullAccess

  private let rootStack = UIStackView()
  private let headerBar = UIView()
  private let brandLabel = UILabel()
  private let countLabel = UILabel()
  private let searchBar = UISearchBar()
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let setupCard = UIView()
  private let setupIcon = UIImageView()
  private let setupTitle = UILabel()
  private let setupBody = UILabel()
  private let primaryButton = UIButton(type: .system)
  private let secondaryButton = UIButton(type: .system)
  private let toolbar = UIStackView()
  private let toast = UILabel()
  private var tableHeightConstraint: NSLayoutConstraint?
  private var setupHeightConstraint: NSLayoutConstraint?

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
      view.heightAnchor.constraint(equalToConstant: 268),
    ])

    // Header
    headerBar.translatesAutoresizingMaskIntoConstraints = false
    headerBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
    let headerRow = UIStackView()
    headerRow.axis = .horizontal
    headerRow.alignment = .center
    headerRow.spacing = 8
    headerRow.translatesAutoresizingMaskIntoConstraints = false
    headerBar.addSubview(headerRow)
    NSLayoutConstraint.activate([
      headerRow.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 14),
      headerRow.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -14),
      headerRow.topAnchor.constraint(equalTo: headerBar.topAnchor),
      headerRow.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
    ])

    let mark = UIView()
    mark.backgroundColor = brand
    mark.layer.cornerRadius = 5
    mark.translatesAutoresizingMaskIntoConstraints = false
    mark.widthAnchor.constraint(equalToConstant: 18).isActive = true
    mark.heightAnchor.constraint(equalToConstant: 18).isActive = true
    let markIcon = UIImageView(image: UIImage(systemName: "doc.on.clipboard.fill"))
    markIcon.tintColor = .white
    markIcon.contentMode = .scaleAspectFit
    markIcon.translatesAutoresizingMaskIntoConstraints = false
    mark.addSubview(markIcon)
    NSLayoutConstraint.activate([
      markIcon.centerXAnchor.constraint(equalTo: mark.centerXAnchor),
      markIcon.centerYAnchor.constraint(equalTo: mark.centerYAnchor),
      markIcon.widthAnchor.constraint(equalToConstant: 10),
      markIcon.heightAnchor.constraint(equalToConstant: 10),
    ])

    brandLabel.text = "ClipVal"
    brandLabel.font = .systemFont(ofSize: 15, weight: .bold)
    brandLabel.textColor = .label

    countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    countLabel.textColor = .secondaryLabel
    countLabel.textAlignment = .right

    headerRow.addArrangedSubview(mark)
    headerRow.addArrangedSubview(brandLabel)
    headerRow.addArrangedSubview(UIView()) // spacer
    headerRow.addArrangedSubview(countLabel)
    rootStack.addArrangedSubview(headerBar)

    // Search (hidden until ready + has items)
    searchBar.searchBarStyle = .minimal
    searchBar.placeholder = "Search"
    searchBar.delegate = self
    searchBar.autocapitalizationType = .none
    searchBar.autocorrectionType = .no
    searchBar.searchTextField.font = .systemFont(ofSize: 15, weight: .regular)
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    searchBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
    let searchWrap = UIView()
    searchWrap.addSubview(searchBar)
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchBar.leadingAnchor.constraint(equalTo: searchWrap.leadingAnchor, constant: 6),
      searchBar.trailingAnchor.constraint(equalTo: searchWrap.trailingAnchor, constant: -6),
      searchBar.topAnchor.constraint(equalTo: searchWrap.topAnchor),
      searchBar.bottomAnchor.constraint(equalTo: searchWrap.bottomAnchor),
      searchWrap.heightAnchor.constraint(equalToConstant: 40),
    ])
    rootStack.addArrangedSubview(searchWrap)

    // Table (ready mode)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 14)
    tableView.backgroundColor = .clear
    tableView.rowHeight = 48
    tableView.showsVerticalScrollIndicator = true
    tableView.register(VaultCell.self, forCellReuseIdentifier: VaultCell.reuseId)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    let th = tableView.heightAnchor.constraint(equalToConstant: 144)
    th.isActive = true
    tableHeightConstraint = th
    rootStack.addArrangedSubview(tableView)

    // Setup card (access / sync)
    setupCard.translatesAutoresizingMaskIntoConstraints = false
    setupCard.backgroundColor = .tertiarySystemBackground
    setupCard.layer.cornerRadius = 14
    let sc = setupCard.heightAnchor.constraint(equalToConstant: 152)
    sc.isActive = true
    setupHeightConstraint = sc

    let setupStack = UIStackView()
    setupStack.axis = .vertical
    setupStack.spacing = 8
    setupStack.alignment = .fill
    setupStack.translatesAutoresizingMaskIntoConstraints = false
    setupCard.addSubview(setupStack)
    NSLayoutConstraint.activate([
      setupStack.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 16),
      setupStack.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -16),
      setupStack.topAnchor.constraint(equalTo: setupCard.topAnchor, constant: 14),
      setupStack.bottomAnchor.constraint(equalTo: setupCard.bottomAnchor, constant: -14),
    ])

    let topRow = UIStackView()
    topRow.axis = .horizontal
    topRow.spacing = 12
    topRow.alignment = .top

    setupIcon.tintColor = brand
    setupIcon.contentMode = .scaleAspectFit
    setupIcon.translatesAutoresizingMaskIntoConstraints = false
    setupIcon.widthAnchor.constraint(equalToConstant: 28).isActive = true
    setupIcon.heightAnchor.constraint(equalToConstant: 28).isActive = true

    let textCol = UIStackView()
    textCol.axis = .vertical
    textCol.spacing = 4
    setupTitle.font = .systemFont(ofSize: 15, weight: .semibold)
    setupTitle.textColor = .label
    setupTitle.numberOfLines = 2
    setupBody.font = .systemFont(ofSize: 12, weight: .regular)
    setupBody.textColor = .secondaryLabel
    setupBody.numberOfLines = 3
    textCol.addArrangedSubview(setupTitle)
    textCol.addArrangedSubview(setupBody)

    topRow.addArrangedSubview(setupIcon)
    topRow.addArrangedSubview(textCol)
    setupStack.addArrangedSubview(topRow)

    primaryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    primaryButton.backgroundColor = brand
    primaryButton.setTitleColor(.white, for: .normal)
    primaryButton.layer.cornerRadius = 10
    primaryButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    primaryButton.addTarget(self, action: #selector(tapPrimary), for: .touchUpInside)

    secondaryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    secondaryButton.setTitleColor(brand, for: .normal)
    secondaryButton.backgroundColor = brandSoft
    secondaryButton.layer.cornerRadius = 10
    secondaryButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
    secondaryButton.addTarget(self, action: #selector(tapSecondary), for: .touchUpInside)

    setupStack.addArrangedSubview(primaryButton)
    setupStack.addArrangedSubview(secondaryButton)

    let setupWrap = UIView()
    setupWrap.addSubview(setupCard)
    setupCard.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      setupCard.leadingAnchor.constraint(equalTo: setupWrap.leadingAnchor, constant: 12),
      setupCard.trailingAnchor.constraint(equalTo: setupWrap.trailingAnchor, constant: -12),
      setupCard.topAnchor.constraint(equalTo: setupWrap.topAnchor, constant: 4),
      setupCard.bottomAnchor.constraint(equalTo: setupWrap.bottomAnchor, constant: -4),
    ])
    rootStack.addArrangedSubview(setupWrap)

    // Toolbar
    toolbar.axis = .horizontal
    toolbar.spacing = 8
    toolbar.distribution = .fillEqually
    toolbar.isLayoutMarginsRelativeArrangement = true
    toolbar.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 4, right: 12)
    toolbar.addArrangedSubview(toolButton(systemName: "delete.left", action: #selector(tapDelete)))
    toolbar.addArrangedSubview(toolButton(title: "Open App", action: #selector(tapOpenApp)))
    toolbar.addArrangedSubview(toolButton(systemName: "globe", action: #selector(tapNextKeyboard)))
    rootStack.addArrangedSubview(toolbar)

    toast.font = .systemFont(ofSize: 11, weight: .semibold)
    toast.textColor = brand
    toast.textAlignment = .center
    toast.alpha = 0
    toast.text = " "
    toast.heightAnchor.constraint(equalToConstant: 16).isActive = true
    rootStack.addArrangedSubview(toast)

    let foot = UILabel()
    foot.text = "On-device only · No keylogging"
    foot.font = .systemFont(ofSize: 10, weight: .medium)
    foot.textColor = .tertiaryLabel
    foot.textAlignment = .center
    foot.heightAnchor.constraint(equalToConstant: 18).isActive = true
    rootStack.addArrangedSubview(foot)
  }

  private func toolButton(title: String? = nil, systemName: String? = nil, action: Selector) -> UIButton {
    let b = UIButton(type: .system)
    if let systemName {
      let img = UIImage(systemName: systemName)
      b.setImage(img, for: .normal)
      b.tintColor = .label
    } else {
      b.setTitle(title, for: .normal)
      b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
      b.setTitleColor(.label, for: .normal)
    }
    b.backgroundColor = .tertiarySystemFill
    b.layer.cornerRadius = 10
    b.heightAnchor.constraint(equalToConstant: 38).isActive = true
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  // MARK: - Mode

  private func applyMode() {
    let ready = mode == .ready
    searchBar.superview?.isHidden = !ready || allItems.count < 5
    tableView.isHidden = !ready
    setupCard.superview?.isHidden = ready
    tableHeightConstraint?.constant = ready ? 144 : 0
    // Taller setup card so steps fit (no dead "button does nothing" UX)
    setupHeightConstraint?.constant = ready ? 0 : 188

    switch mode {
    case .needsFullAccess:
      countLabel.text = "Setup"
      setupIcon.image = UIImage(systemName: "lock.open.fill")
      setupTitle.text = "Enable Full Access first"
      // Apple blocks openURL from keyboards until Full Access is ON.
      // Fake "Open Settings" buttons feel broken — show real steps instead.
      setupBody.text =
        "iOS blocks buttons here until Full Access is on.\n"
        + "1. Leave keyboard → Settings\n"
        + "2. General → Keyboard → Keyboards → ClipVal\n"
        + "3. Turn on Allow Full Access\n"
        + "4. Return here · Open ClipVal once"
      primaryButton.setTitle("I’ve enabled it — Refresh", for: .normal)
      primaryButton.tag = 1
      secondaryButton.setTitle("Try Open ClipVal", for: .normal)
      secondaryButton.isHidden = false
    case .needsSync:
      countLabel.text = "Almost ready"
      setupIcon.image = UIImage(systemName: "arrow.triangle.2.circlepath")
      setupTitle.text = "Open ClipVal once"
      setupBody.text =
        "Full Access is on. Open the ClipVal app so pinned & recent items sync to this keyboard."
      primaryButton.setTitle("Open ClipVal", for: .normal)
      primaryButton.tag = 2
      secondaryButton.setTitle("Refresh list", for: .normal)
      secondaryButton.isHidden = false
    case .ready:
      let n = visible.count
      countLabel.text = n == 0 ? "No matches" : "\(n) item\(n == 1 ? "" : "s")"
      secondaryButton.isHidden = true
    }
  }

  // MARK: - Data

  private func reloadItems() {
    if !hasFullAccess {
      mode = .needsFullAccess
      allItems = []
      visible = []
      applyMode()
      tableView.reloadData()
      return
    }

    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.synchronize()
    // Prefer keyboard payload; also try Data form; fallback widget JSON
    let raw = Self.readAppGroupString(defaults: defaults, key: keyboardItemsKey)
      ?? Self.readAppGroupString(defaults: defaults, key: widgetItemsKey)

    guard let raw,
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(KeyboardPayload.self, from: data)
    else {
      mode = .needsSync
      allItems = []
      visible = []
      applyMode()
      tableView.reloadData()
      return
    }

    allItems = payload.items
      .filter { ($0.sensitive != true) && !$0.value.isEmpty }
      .map { item in
        // Prefer per-id native key if present (writeSnapshot)
        if let v = defaults?.string(forKey: "wv_\(item.id)"), !v.isEmpty {
          return KeyboardItem(
            id: item.id,
            title: item.title,
            value: v,
            monogram: item.monogram,
            pinned: item.pinned,
            sensitive: item.sensitive
          )
        }
        return item
      }
    allItems.sort { a, b in
      if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
      return a.displayTitle.localizedCaseInsensitiveCompare(b.displayTitle) == .orderedAscending
    }
    if allItems.count > 40 { allItems = Array(allItems.prefix(40)) }

    if allItems.isEmpty {
      mode = .needsSync
    } else {
      mode = .ready
    }
    applyFilter()
  }

  private static func readAppGroupString(defaults: UserDefaults?, key: String) -> String? {
    if let s = defaults?.string(forKey: key), !s.isEmpty { return s }
    if let data = defaults?.data(forKey: key), let s = String(data: data, encoding: .utf8), !s.isEmpty {
      return s
    }
    return nil
  }

  private func applyFilter() {
    let q = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if q.isEmpty {
      visible = allItems
    } else {
      visible = allItems.filter { $0.displayTitle.lowercased().contains(q) }
    }
    applyMode()
    tableView.reloadData()
  }

  // MARK: - Actions

  @objc private func tapPrimary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if primaryButton.tag == 1 {
      // needsFullAccess: refresh after user enabled manually
      reloadItems()
      if mode == .needsFullAccess {
        flash("Still off — Settings → Keyboard → ClipVal → Full Access")
      } else if mode == .needsSync {
        flash("Full Access OK · open ClipVal once")
      } else {
        flash("Ready · tap an item to insert")
      }
    } else {
      // needsSync: open app
      openURL(URL(string: "clipval://vault")!) { ok in
        if !ok { self.flash("Couldn’t open app — switch to ClipVal manually") }
      }
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
      flash("Enable Full Access first — iOS blocks Open App from keyboard")
      return
    }
    openURL(URL(string: "clipval://vault")!) { ok in
      if !ok {
        self.flash("Open ClipVal from Home Screen, then return")
      }
    }
  }

  @objc private func tapSecondary() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    switch mode {
    case .needsFullAccess:
      flash("iOS blocks Open App until Full Access is ON")
      // Still try — rarely works if user partially granted
      openURL(URL(string: "clipval://vault")!) { ok in
        if ok { self.flash("Opened ClipVal") }
      }
    case .needsSync:
      reloadItems()
      flash(mode == .ready ? "Vault loaded" : "Still empty — open ClipVal app once")
    case .ready:
      break
    }
  }

  /// Open URL from keyboard extension. Fails silently without Full Access (Apple policy).
  private func openURL(_ url: URL, completion: ((Bool) -> Void)? = nil) {
    // 1) Responder chain (classic keyboard trick)
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

    // 2) extensionContext (works for some extension types; often no for keyboard)
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
      flash("Nothing to insert — open ClipVal")
      return
    }
    textDocumentProxy.insertText(item.value)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    flash("Inserted · \(item.displayTitle)")
  }

  private func flash(_ text: String) {
    toast.text = text
    toast.alpha = 1
    toast.numberOfLines = 2
    UIView.animate(withDuration: 0.25, delay: 1.6, options: .curveEaseOut) {
      self.toast.alpha = 0
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

  // MARK: - Table

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    visible.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: VaultCell.reuseId, for: indexPath) as! VaultCell
    let item = visible[indexPath.row]
    cell.configure(item: item)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    insert(visible[indexPath.row])
  }
}

// MARK: - Cell

private final class VaultCell: UITableViewCell {
  static let reuseId = "vault"
  private let avatar = UILabel()
  private let titleLabel = UILabel()
  private let pinView = UIImageView()
  private let chevron = UIImageView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .default

    let circle = UIView()
    circle.backgroundColor = brandSoft
    circle.layer.cornerRadius = 16
    circle.translatesAutoresizingMaskIntoConstraints = false

    avatar.font = .systemFont(ofSize: 13, weight: .bold)
    avatar.textColor = brand
    avatar.textAlignment = .center
    avatar.translatesAutoresizingMaskIntoConstraints = false
    circle.addSubview(avatar)

    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.lineBreakMode = .byTruncatingTail

    pinView.image = UIImage(systemName: "pin.fill")
    pinView.tintColor = brand
    pinView.contentMode = .scaleAspectFit
    pinView.isHidden = true

    chevron.image = UIImage(systemName: "plus.circle.fill")
    chevron.tintColor = brand.withAlphaComponent(0.85)
    chevron.contentMode = .scaleAspectFit

    let row = UIStackView(arrangedSubviews: [circle, titleLabel, pinView, chevron])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    row.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(row)

    NSLayoutConstraint.activate([
      circle.widthAnchor.constraint(equalToConstant: 32),
      circle.heightAnchor.constraint(equalToConstant: 32),
      avatar.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
      pinView.widthAnchor.constraint(equalToConstant: 12),
      pinView.heightAnchor.constraint(equalToConstant: 12),
      chevron.widthAnchor.constraint(equalToConstant: 22),
      chevron.heightAnchor.constraint(equalToConstant: 22),
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:)") }

  func configure(item: KeyboardItem) {
    avatar.text = item.monogramLetter
    titleLabel.text = item.displayTitle
    pinView.isHidden = !item.isPinned
  }
}
