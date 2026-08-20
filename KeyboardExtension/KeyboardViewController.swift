import UIKit

final class KeyboardViewController: UIInputViewController {
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let keyboardStack = UIStackView()
    private var heightConstraint: NSLayoutConstraint!
    private var calloutView: KeyCalloutView?
    private var currentKey: KeyboardKey?
    private var isShifted = true

    // Keep the extension lightweight: no image caches, model objects, or third-party frameworks.
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        buildKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keyboard extensions do not always receive a useful safe-area inset. The constraint
        // still lets iOS account for the home indicator when one is present.
        heightConstraint?.constant = traitCollection.horizontalSizeClass == .compact ? 265 : 300
    }

    private func configureView() {
        view.backgroundColor = .clear

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.masksToBounds = true
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        keyboardStack.axis = .vertical
        keyboardStack.alignment = .fill
        keyboardStack.distribution = .fillEqually
        keyboardStack.spacing = 6
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(keyboardStack)

        let bottom = keyboardStack.bottomAnchor.constraint(
            lessThanOrEqualTo: backgroundView.contentView.safeAreaLayoutGuide.bottomAnchor,
            constant: -6
        )
        NSLayoutConstraint.activate([
            keyboardStack.leadingAnchor.constraint(equalTo: backgroundView.contentView.leadingAnchor, constant: 3),
            keyboardStack.trailingAnchor.constraint(equalTo: backgroundView.contentView.trailingAnchor, constant: -3),
            keyboardStack.topAnchor.constraint(equalTo: backgroundView.contentView.safeAreaLayoutGuide.topAnchor, constant: 6),
            bottom
        ])

        heightConstraint = view.heightAnchor.constraint(equalToConstant: 265)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }

    private func buildKeyboard() {
        let letters = [
            Array("QWERTYUIOP"),
            Array("ASDFGHJKL"),
            Array("ZXCVBNM")
        ]

        for (index, row) in letters.enumerated() {
            let rowStack = makeRow()
            if index == 1 { rowStack.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18); rowStack.isLayoutMarginsRelativeArrangement = true }
            if index == 2 {
                rowStack.addArrangedSubview(makeKey(title: "⇧", role: .shift, weight: 1.35))
            }
            row.forEach { rowStack.addArrangedSubview(makeKey(title: String($0), role: .character)) }
            if index == 2 {
                rowStack.addArrangedSubview(makeKey(title: "⌫", role: .delete, weight: 1.35))
            }
            keyboardStack.addArrangedSubview(rowStack)
        }

        let bottom = makeRow()
        bottom.addArrangedSubview(makeKey(title: "123", role: .nextKeyboard, weight: 1.2))
        bottom.addArrangedSubview(makeKey(title: "🌐", role: .nextKeyboard, weight: 1.0))
        bottom.addArrangedSubview(makeKey(title: "空格", role: .space, weight: 4.6))
        bottom.addArrangedSubview(makeKey(title: "return", role: .returnKey, weight: 1.7))
        keyboardStack.addArrangedSubview(bottom)
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillProportionally
        row.spacing = 4
        return row
    }

    private func makeKey(title: String, role: KeyboardKey.Role, weight: CGFloat = 1) -> KeyboardKey {
        let key = KeyboardKey(title: title, role: role)
        key.translatesAutoresizingMaskIntoConstraints = false
        key.setContentCompressionResistancePriority(.required, for: .horizontal)
        key.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
        key.addTarget(self, action: #selector(keyUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        key.widthWeight = weight
        key.accessibilityTraits = role == .shift ? [.button, .selected] : .button
        return key
    }

    @objc private func keyDown(_ sender: KeyboardKey) {
        currentKey = sender
        showCallout(for: sender)
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    @objc private func keyUp(_ sender: KeyboardKey) {
        hideCallout()
        guard sender === currentKey else { return }
        currentKey = nil

        switch sender.role {
        case .character:
            let text = isShifted ? sender.keyTitle.uppercased() : sender.keyTitle.lowercased()
            textDocumentProxy.insertText(text)
            isShifted = false
        case .space: textDocumentProxy.insertText(" ")
        case .delete: textDocumentProxy.deleteBackward()
        case .returnKey: textDocumentProxy.insertText("\n")
        case .nextKeyboard: advanceToNextInputMode()
        case .shift:
            isShifted.toggle()
            updateCharacterTitles()
        }

        // Third-party keyboard audio is controlled by iOS. Keep the extension silent by
        // default to avoid an unnecessary framework dependency and reduce memory usage.
    }

    private func updateCharacterTitles() {
        keyboardStack.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? KeyboardKey }
            .filter { $0.role == .character }
            .forEach { $0.setTitle(isShifted ? $0.keyTitle.uppercased() : $0.keyTitle.lowercased(), for: .normal) }
    }

    private func showCallout(for key: KeyboardKey) {
        guard key.role == .character || key.role == .space else { return }
        hideCallout()
        let callout = KeyCalloutView(text: key.keyTitle)
        callout.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(callout)
        let point = key.convert(CGPoint(x: key.bounds.midX, y: 0), to: view)
        NSLayoutConstraint.activate([
            callout.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: point.x),
            callout.bottomAnchor.constraint(equalTo: view.topAnchor, constant: point.y + 2),
            callout.widthAnchor.constraint(equalToConstant: 58),
            callout.heightAnchor.constraint(equalToConstant: 72)
        ])
        calloutView = callout
    }

    private func hideCallout() {
        calloutView?.removeFromSuperview()
        calloutView = nil
    }
}

final class KeyboardKey: UIButton {
    enum Role: Equatable { case character, space, delete, shift, nextKeyboard, returnKey }
    let role: Role
    let keyTitle: String
    var widthWeight: CGFloat = 1

    init(title: String, role: Role) {
        self.role = role
        self.keyTitle = title
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: role == .character ? 22 : 15)
        setTitleColor(.label, for: .normal)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        CGSize(width: max(1, widthWeight * 30), height: 44)
    }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .systemGray : .secondarySystemBackground }
    }
}

final class KeyCalloutView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 38)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor), label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
