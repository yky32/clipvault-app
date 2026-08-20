import UIKit

// MARK: - App Group (same as Widget / Share)

private let appGroupId = "group.com.clipval"
/// Reuse widget snapshot — already pinned + recent. Keyboard never hits network.
private let itemsKey = "widget_items_json"
private let brand = UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1)

private struct KeyboardItem: Codable, Hashable {
  let id: String
  let title: String
  let value: String
  let monogram: String?
  let pinned: Bool?
  let sensitive: Bool?

  var isSensitive: Bool { sensitive == true }

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

/// Custom keyboard: insert vault snippets into the host field.
///
/// Apple-risk posture:
/// - No URLSession / no network capability
/// - No keystroke logging or analytics
/// - Skips `sensitive` items (open main app instead)
/// - Full Access only for App Group read (system requirement)
/// - Always shows next-keyboard (globe) control
final class KeyboardViewController: UIInputViewController {
  private var items: [KeyboardItem] = []
  private var collection: UICollectionView!
  private var emptyLabel: UILabel!
  private var statusLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.secondarySystemBackground
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
    root.spacing = 8
    root.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(root)

    NSLayoutConstraint.activate([
      root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
      root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
      view.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
    ])

    // Header
    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8

    let title = UILabel()
    title.text = "ClipVal"
    title.font = .systemFont(ofSize: 15, weight: .semibold)
    title.textColor = brand

    statusLabel = UILabel()
    statusLabel.font = .systemFont(ofSize: 11, weight: .regular)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .right
    statusLabel.numberOfLines = 2

    header.addArrangedSubview(title)
    header.addArrangedSubview(statusLabel)
    root.addArrangedSubview(header)

    // Grid
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.reuseId)
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

    // Toolbar: delete · open app · next keyboard
    let bar = UIStackView()
    bar.axis = .horizontal
    bar.spacing = 10
    bar.distribution = .fillEqually

    bar.addArrangedSubview(makeBarButton(title: "⌫", action: #selector(tapDelete)))
    bar.addArrangedSubview(makeBarButton(title: "Open ClipVal", action: #selector(tapOpenApp)))
    bar.addArrangedSubview(makeBarButton(title: "🌐", action: #selector(tapNextKeyboard)))

    root.addArrangedSubview(bar)

    let foot = UILabel()
    foot.text = "Titles only · Sensitive items hidden · No keylogging"
    foot.font = .systemFont(ofSize: 10, weight: .medium)
    foot.textColor = .tertiaryLabel
    foot.textAlignment = .center
    root.addArrangedSubview(foot)
  }

  private func makeBarButton(title: String, action: Selector) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    b.backgroundColor = UIColor.tertiarySystemFill
    b.layer.cornerRadius = 8
    b.heightAnchor.constraint(equalToConstant: 40).isActive = true
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }

  // MARK: - Data

  private func reloadItems() {
    // Full Access off → App Group often empty. Be honest in UI (no crash).
    guard openAccessEnabled else {
      items = []
      statusLabel.text = "Enable Full Access in Settings → ClipVal Keyboard"
      emptyLabel.isHidden = false
      emptyLabel.text =
        "Apple requires Full Access for a keyboard to read your vault snapshot from ClipVal.\n\n"
        + "ClipVal does not log keys and does not use the network in this keyboard.\n\n"
        + "Settings → General → Keyboard → Keyboards → ClipVal → Allow Full Access."
      collection.reloadData()
      return
    }

    guard let defaults = UserDefaults(suiteName: appGroupId),
          let raw = defaults.string(forKey: itemsKey),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(KeyboardPayload.self, from: data)
    else {
      items = []
      statusLabel.text = "Open ClipVal once to refresh"
      emptyLabel.isHidden = false
      emptyLabel.text =
        "No snapshot yet. Open the ClipVal app so it can cache pinned & recent items for the keyboard."
      collection.reloadData()
      return
    }

    // Policy: never surface sensitive values on the keyboard surface.
    items = payload.items.filter { !$0.isSensitive && !$0.value.isEmpty }
    // Cap UI density
    if items.count > 16 {
      items = Array(items.prefix(16))
    }
    statusLabel.text = items.isEmpty ? "No items" : "\(items.count) ready · tap to insert"
    emptyLabel.isHidden = !items.isEmpty
    emptyLabel.text = items.isEmpty
      ? "Pin items or copy once in ClipVal. Sensitive items never appear here."
      : nil
    collection.reloadData()
  }

  private var openAccessEnabled: Bool {
    // UIInputViewController.hasFullAccess (iOS 11+)
    return hasFullAccess
  }

  // MARK: - Actions

  @objc private func tapDelete() {
    textDocumentProxy.deleteBackward()
  }

  @objc private func tapNextKeyboard() {
    advanceToNextInputMode()
  }

  @objc private func tapOpenApp() {
    // openURL from keyboard requires Full Access; fails softly otherwise.
    guard let url = URL(string: "clipval://") else { return }
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        app.open(url, options: [:], completionHandler: nil)
        return
      }
      // Selector openURL for extension context
      if r.responds(to: Selector(("openURL:"))) {
        r.perform(Selector(("openURL:")), with: url)
        return
      }
      responder = r.next
    }
    extensionContext?.open(url, completionHandler: nil)
  }

  private func insert(_ item: KeyboardItem) {
    let value = item.value
    guard !value.isEmpty else { return }
    textDocumentProxy.insertText(value)
    let gen = UIImpactFeedbackGenerator(style: .light)
    gen.impactOccurred()
  }
}

// MARK: - Collection

extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ChipCell.reuseId,
      for: indexPath
    ) as! ChipCell
    cell.configure(title: items[indexPath.item].displayTitle, pinned: items[indexPath.item].pinned == true)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    insert(items[indexPath.item])
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let w = collectionView.bounds.width
    let cols: CGFloat = w > 400 ? 3 : 2
    let spacing: CGFloat = 8
    let width = floor((w - spacing * (cols - 1)) / cols)
    return CGSize(width: max(width, 100), height: 40)
  }
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

    label.font = .systemFont(ofSize: 14, weight: .medium)
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
      contentView.backgroundColor = isHighlighted ? brand.withAlphaComponent(0.15) : .tertiarySystemBackground
    }
  }

  private var brand: UIColor { UIColor(red: 0.76, green: 0.36, blue: 0.28, alpha: 1) }
}
