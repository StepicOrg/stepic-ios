import SnapKit
import UIKit

protocol NewCodeQuizViewDelegate: class {
    func newCodeQuizView(_ view: NewCodeQuizView, didSelectLanguage language: String)
    func newCodeQuizViewDidRequestFullscreen(_ view: NewCodeQuizView)
}

extension NewCodeQuizView {
    struct Appearance {
        let separatorColor = UIColor(hex: 0xEAECF0)
        let separatorHeight: CGFloat = 1

        let codeTextViewHeight: CGFloat = 236
    }
}

final class NewCodeQuizView: UIView {
    let appearance: Appearance
    weak var delegate: NewCodeQuizViewDelegate?

    private lazy var codeDetailsView = CodeDetailsView()

    private lazy var languagePickerView: CodeLanguagePickerView = {
        let languagePickerView = CodeLanguagePickerView()
        languagePickerView.delegate = self
        return languagePickerView
    }()

    private lazy var toolbarView: CodeToolbarView = {
        let toolbarView = CodeToolbarView()
        toolbarView.onPickLanguageButtonClick = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            if strongSelf.languagePickerView.languages.isEmpty {
                strongSelf.toolbarView.toggleLanguagePickerButton()
            } else {
                strongSelf.languagePickerView.isHidden.toggle()
                strongSelf.codeEditorStackView.isHidden = !strongSelf.languagePickerView.isHidden
            }
        }
        toolbarView.onFullscreenButtonClick = { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.delegate?.newCodeQuizViewDidRequestFullscreen(strongSelf)
        }
        return toolbarView
    }()

    private lazy var codeTextView = CodeTextView()

    private lazy var codeEditorStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [
                self.makeSeparatorView(),
                self.codeTextView,
                self.makeSeparatorView()
            ]
        )
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [
                self.codeDetailsView,
                self.toolbarView,
                self.codeEditorStackView,
                self.languagePickerView
            ]
        )
        stackView.axis = .vertical
        return stackView
    }()

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

    func configure(viewModel: NewCodeQuizViewModel) {
        self.detailsView.configure(samples: viewModel.samples, limit: viewModel.limit)
        self.codeDetailsView.configure(samples: viewModel.samples, limit: viewModel.limit)
        self.languagePickerView.languages = viewModel.languages
        self.toolbarView.language = viewModel.language
        self.codeTextView.language = viewModel.language
        self.codeTextView.text = viewModel.code
    }

    // MARK: - Private API

    private func setActionControlsEnabled(_ enabled: Bool) {
        self.toolbarView.isEnabled = enabled
        self.codeTextView.isEditable = enabled
    }

    private func makeSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = self.appearance.separatorColor
        view.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.separatorHeight)
        }
        return view
    }
}

extension NewCodeQuizView: ProgrammaticallyInitializableViewProtocol {
    func setupView() { }

    func addSubviews() {
        self.addSubview(self.stackView)
    }

    func makeConstraints() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.codeTextView.translatesAutoresizingMaskIntoConstraints = false
        self.codeTextView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.codeTextViewHeight)
        }
    }
}

extension NewCodeQuizView: CodeLanguagePickerViewDelegate {
    func codeLanguagePickerView(_ view: CodeLanguagePickerView, didSelectLanguage language: String) {
        self.delegate?.newCodeQuizView(self, didSelectLanguage: language)
        self.toolbarView.collapseLanguagePickerButton()
    }
}
