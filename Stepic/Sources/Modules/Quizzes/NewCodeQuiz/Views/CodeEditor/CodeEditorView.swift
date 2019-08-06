import SnapKit
import UIKit

protocol CodeEditorViewDelegate: class {
    func codeEditorViewDidChange(_ codeEditorView: CodeEditorView)
    func codeEditorView(_ codeEditorView: CodeEditorView, beginEditing editing: Bool)
    func codeEditorViewDidBeginEditing(_ codeEditorView: CodeEditorView)
    func codeEditorViewDidEndEditing(_ codeEditorView: CodeEditorView)

    func codeEditorViewDidRequestSuggestionPresentationController(_ codeEditorView: CodeEditorView) -> UIViewController?
}

extension CodeEditorViewDelegate {
    func codeEditorViewDidChange(_ codeEditorView: CodeEditorView) { }

    func codeEditorView(_ codeEditorView: CodeEditorView, beginEditing editing: Bool) { }

    func codeEditorViewDidBeginEditing(_ codeEditorView: CodeEditorView) { }

    func codeEditorViewDidEndEditing(_ codeEditorView: CodeEditorView) { }

    func codeEditorViewDidRequestSuggestionPresentationController(
        _ codeEditorView: CodeEditorView
    ) -> UIViewController? {
        return nil
    }
}

extension CodeEditorView {
    struct Appearance {
        let languageNameLabelLayoutInsets = LayoutInsets(top: 8, right: 16)
        let languageNameLabelTextColor = UIColor.mainDark
        let languageNameLabelBackgroundColor = UIColor(hex: 0xF6F6F6).withAlphaComponent(0.75)
        let languageNameLabelFont = UIFont.systemFont(ofSize: 10)
        let languageNameLabelInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        let languageNameLabelCornerRadius: CGFloat = 10
    }
}

final class CodeEditorView: UIView {
    let appearance: Appearance
    weak var delegate: CodeEditorViewDelegate?

    private lazy var codeTextView: CodeTextView = {
        let codeTextView = CodeTextView()
        codeTextView.delegate = self

        codeTextView.autocapitalizationType = .none
        codeTextView.autocorrectionType = .no
        codeTextView.spellCheckingType = .no

        if #available(iOS 11.0, *) {
            codeTextView.smartDashesType = .no
            codeTextView.smartQuotesType = .no
            codeTextView.smartInsertDeleteType = .no
        }

        return codeTextView
    }()

    private lazy var languageNameLabel: UILabel = {
        let label = PaddingLabel(padding: self.appearance.languageNameLabelInsets)
        label.textAlignment = .center

        label.clipsToBounds = true
        label.layer.cornerRadius = self.appearance.languageNameLabelCornerRadius

        label.textColor = self.appearance.languageNameLabelTextColor
        label.backgroundColor = self.appearance.languageNameLabelBackgroundColor
        label.font = self.appearance.languageNameLabelFont

        return label
    }()

    private let codePlaygroundManager = CodePlaygroundManager()
    // Uses by codePlaygroundManager for analysis between current code and old one (suggestions & completions).
    private var oldCode: String?

    private let elementsSize: CodeQuizElementsSize = DeviceInfo.current.isPad ? .big : .small
    private var tabSize = 0

    var code: String? {
        get {
            return self.codeTextView.text
        }
        set {
            self.codeTextView.text = newValue
            if self.oldCode == nil {
                self.oldCode = newValue
            }
        }
    }

    var codeTemplate: String? {
        didSet {
            self.tabSize = self.codePlaygroundManager.countTabSize(text: self.codeTemplate ?? "")
        }
    }

    var language: CodeLanguage? {
        didSet {
            self.codeTextView.language = self.language?.highlightr
            self.languageNameLabel.text = self.language?.rawValue
            self.setupAccessoryView(isEditable: self.isEditable)
        }
    }

    var theme: CodeEditorTheme? {
        didSet {
            if let theme = self.theme {
                self.codeTextView.updateTheme(name: theme.name, font: theme.font)
            }
        }
    }

    var isThemeAutoUpdating: Bool = true

    var isEditable = true {
        didSet {
            self.setupAccessoryView(isEditable: self.isEditable)
        }
    }

    var isLanguageNameVisible = false {
        didSet {
            self.languageNameLabel.isHidden = self.isLanguageNameVisible
            self.languageNameLabel.alpha = self.isLanguageNameVisible ? 1 : 0
        }
    }

    var textInsets: UIEdgeInsets = .zero {
        didSet {
            self.codeTextView.textContainerInset = self.textInsets
        }
    }

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()

        self.updateThemeIfAutoEnabled()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.themeDidChange),
            name: .codeEditorThemeDidChange,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupAccessoryView(isEditable: Bool) {
        defer {
            self.codeTextView.reloadInputViews()
        }

        guard let language = self.language, isEditable else {
            self.codeTextView.inputAccessoryView = nil
            return
        }

        self.codeTextView.inputAccessoryView = InputAccessoryBuilder.buildAccessoryView(
            size: self.elementsSize.elements.toolbar,
            language: language,
            tabAction: { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.codePlaygroundManager.insertAtCurrentPosition(
                    symbols: String(repeating: " ", count: strongSelf.tabSize),
                    textView: strongSelf.codeTextView
                )
            },
            insertStringAction: { [weak self] symbols in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.codePlaygroundManager.insertAtCurrentPosition(
                    symbols: symbols,
                    textView: strongSelf.codeTextView
                )
                strongSelf.analyzeCodeAndComplete()
            },
            hideKeyboardAction: { [weak self] in
                self?.codeTextView.resignFirstResponder()
            }
        )
    }

    private func analyzeCodeAndComplete() {
        guard let language = self.language,
              let viewController = self.delegate?.codeEditorViewDidRequestSuggestionPresentationController(self) else {
            return
        }

        self.codePlaygroundManager.analyzeAndComplete(
            textView: self.codeTextView,
            previousText: self.oldCode ?? "",
            language: language,
            tabSize: self.tabSize,
            inViewController: viewController,
            suggestionsDelegate: self
        )

        self.oldCode = self.code
    }

    @objc
    private func themeDidChange() {
        self.updateThemeIfAutoEnabled()
    }

    private func updateThemeIfAutoEnabled() {
        if self.isThemeAutoUpdating {
            self.theme = CodeEditorThemeService().theme
        }
    }
}

extension CodeEditorView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.isLanguageNameVisible = false
    }

    func addSubviews() {
        self.addSubview(self.codeTextView)
        self.addSubview(self.languageNameLabel)
    }

    func makeConstraints() {
        self.codeTextView.translatesAutoresizingMaskIntoConstraints = false
        self.codeTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.languageNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.languageNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(self.appearance.languageNameLabelLayoutInsets.top)
            make.trailing.equalToSuperview().offset(-self.appearance.languageNameLabelLayoutInsets.right)
        }
    }
}

extension CodeEditorView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.delegate?.codeEditorView(self, beginEditing: self.isEditable)
        return self.isEditable
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.codeEditorViewDidBeginEditing(self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.codeEditorViewDidEndEditing(self)
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "\n"
            DispatchQueue.main.async {
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        }

        self.analyzeCodeAndComplete()
        self.delegate?.codeEditorViewDidChange(self)
    }

    @available(iOS 10.0, *)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        return false
    }

    @available(iOS 10.0, *)
    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        return false
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return false
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange
    ) -> Bool {
        return false
    }
}

extension CodeEditorView: CodeSuggestionDelegate {
    func didSelectSuggestion(suggestion: String, prefix: String) {
        guard self.codeTextView.isEditable else {
            return
        }

        self.codeTextView.becomeFirstResponder()

        let symbols = String(suggestion[suggestion.index(suggestion.startIndex, offsetBy: prefix.count)...])
        self.codePlaygroundManager.insertAtCurrentPosition(symbols: symbols, textView: self.codeTextView)

        self.analyzeCodeAndComplete()
    }

    var suggestionsSize: CodeSuggestionsSize {
        return self.elementsSize.elements.suggestions
    }
}
