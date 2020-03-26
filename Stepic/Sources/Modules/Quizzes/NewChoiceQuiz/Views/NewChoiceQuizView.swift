import SnapKit
import UIKit

protocol NewChoiceQuizViewDelegate: AnyObject {
    func newChoiceQuizView(_ view: NewChoiceQuizView, didReport selectionMask: [Bool])
}

extension NewChoiceQuizView {
    struct Appearance {
        let spacing: CGFloat = 16
        let insets = LayoutInsets(left: 16, right: 16)

        let titleColor = UIColor.stepikAccent
        let titleFont = UIFont.systemFont(ofSize: 12, weight: .medium)

        let loadingIndicatorColor = UIColor.stepikLoadingIndicator
    }

    enum Animation {
        static let appearanceAnimationDuration: TimeInterval = 0.2
        static let appearanceAnimationDelay: TimeInterval = 1.0
    }
}

final class NewChoiceQuizView: UIView {
    let appearance: Appearance
    weak var delegate: NewChoiceQuizViewDelegate?

    private lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let loadingIndicatorView = UIActivityIndicatorView(style: .white)
        loadingIndicatorView.color = self.appearance.loadingIndicatorColor
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.startAnimating()
        return loadingIndicatorView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.appearance.titleColor
        label.font = self.appearance.titleFont
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [self.titleLabelContainerView, self.choicesContainerView]
        )
        stackView.axis = .vertical
        stackView.spacing = self.appearance.spacing
        return stackView
    }()

    private lazy var choicesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = self.appearance.spacing
        return stackView
    }()

    private lazy var choicesContainerView = UIView()
    private lazy var titleLabelContainerView = UIView()

    private var loadGroup: DispatchGroup?

    var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }

    var isSingleChoice = true
    private var isSelectionEnabled = true

    // swiftlint:disable:next discouraged_optional_collection
    private var selectionMask: [Bool]?

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func updateFeedback(text: [String?]) {
        assert(self.choicesStackView.arrangedSubviews.count == text.count)

        for (index, hint) in text.enumerated() {
            guard let choiceView = self.choicesStackView.arrangedSubviews[safe: index] as? ChoiceElementView else {
                continue
            }

            choiceView.hint = hint
        }
    }

    func markSelectedAsCorrect() {
        self.isSelectionEnabled = false
        self.updateSelected(state: .correct)
        self.updateEnabled(false)
    }

    func markSelectedAsWrong() {
        self.isSelectionEnabled = false
        self.updateSelected(state: .wrong)
        self.updateEnabled(false)
    }

    func reset() {
        // Reset if only view is in correct / wrong state
        if self.isSelectionEnabled {
            return
        }

        self.isSelectionEnabled = true
        self.updateSelected(state: .default)
        self.updateEnabled(true)
    }

    func set(choices: [(text: String, isSelected: Bool)]) {
        self.startLoading()

        self.loadGroup = DispatchGroup()
        self.loadGroup?.notify(queue: .main) { [weak self] in
            // dispatch_group_leave call isn't balanced with dispatch_group_enter, deinit dispatch_group_t here to
            // prevent possible future call to leave onContentLoad.
            self?.loadGroup = nil
            self?.endLoading()
        }

        if !self.choicesStackView.arrangedSubviews.isEmpty {
            self.choicesStackView.removeAllArrangedSubviews()
        }

        for (index, choice) in choices.enumerated() {
            let view = self.makeChoiceView(text: choice.text)
            view.tag = index

            self.loadGroup?.enter()
            view.onContentLoad = { [weak self] in
                self?.loadGroup?.leave()
            }

            self.choicesStackView.addArrangedSubview(view)
        }

        self.selectionMask = choices.map { $0.isSelected }
        self.updateSelected(state: .selected)
    }

    // MARK: - Private API

    func startLoading() {
        self.choicesStackView.alpha = 0.0
        self.loadingIndicatorView.startAnimating()
    }

    func endLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Animation.appearanceAnimationDelay) {
            self.loadingIndicatorView.stopAnimating()

            UIView.animate(
                withDuration: Animation.appearanceAnimationDuration,
                animations: {
                    self.choicesStackView.alpha = 1.0
                }
            )
        }
    }

    private func updateEnabled(_ isEnabled: Bool) {
        for view in self.choicesStackView.arrangedSubviews {
            if let elementView = view as? ChoiceElementView {
                elementView.isEnabled = isEnabled
            }
        }
    }

    private func updateSelected(state: ChoiceElementView.State) {
        guard let selectionMask = self.selectionMask else {
            return
        }

        assert(self.choicesStackView.arrangedSubviews.count == selectionMask.count)

        for (isSelected, view) in zip(selectionMask, self.choicesStackView.arrangedSubviews) {
            if let elementView = view as? ChoiceElementView, isSelected {
                elementView.state = state
            }
        }
    }

    private func makeChoiceView(text: String) -> ChoiceElementView {
        let view = ChoiceElementView()
        view.text = text
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.choiceSelected(_:)))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        return view
    }

    @objc
    private func choiceSelected(_ sender: UITapGestureRecognizer) {
        guard self.isSelectionEnabled else {
            return
        }

        guard let choiceViewTag = sender.view?.tag else {
            return
        }

        guard let choiceView = self.choicesStackView.arrangedSubviews[safe: choiceViewTag] as? ChoiceElementView else {
            return
        }

        if choiceView.state == .default {
            choiceView.state = .selected
        } else if choiceView.state == .selected {
            choiceView.state = .default
        }

        if self.isSingleChoice {
            for view in self.choicesStackView.arrangedSubviews where view !== choiceView {
                (view as? ChoiceElementView)?.state = .default
            }
        }

        let selectionMask = self.choicesStackView.arrangedSubviews
            .map { $0 as? ChoiceElementView }
            .map { view -> Bool in
                if let view = view {
                    return view.state == .selected
                }
                return false
            }
        self.delegate?.newChoiceQuizView(self, didReport: selectionMask)
        self.selectionMask = selectionMask
    }
}

extension NewChoiceQuizView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.stackView)

        self.choicesContainerView.addSubview(self.choicesStackView)
        self.titleLabelContainerView.addSubview(self.titleLabel)

        self.addSubview(self.loadingIndicatorView)
    }

    func makeConstraints() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(self.appearance.insets.left)
            make.trailing.equalToSuperview().offset(-self.appearance.insets.right)
        }

        self.choicesStackView.translatesAutoresizingMaskIntoConstraints = false
        self.choicesStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(self.appearance.insets.left)
            make.trailing.equalToSuperview().offset(-self.appearance.insets.right)
        }

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

extension NewChoiceQuizView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
