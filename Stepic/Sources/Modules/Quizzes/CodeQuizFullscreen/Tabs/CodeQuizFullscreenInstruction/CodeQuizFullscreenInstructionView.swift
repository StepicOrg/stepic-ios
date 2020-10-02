import SnapKit
import UIKit

protocol CodeQuizFullscreenInstructionViewDelegate: AnyObject {
    func codeQuizFullscreenInstructionViewDidLoadContent(_ view: CodeQuizFullscreenInstructionView)
    func codeQuizFullscreenInstructionView(_ view: CodeQuizFullscreenInstructionView, didRequestOpenURL url: URL)
    func codeQuizFullscreenInstructionView(
        _ view: CodeQuizFullscreenInstructionView,
        didRequestFullscreenImage url: URL
    )
}

extension CodeQuizFullscreenInstructionView {
    struct Appearance {
        let loadingIndicatorColor = UIColor.stepikLoadingIndicator
        let spacing: CGFloat = 16

        let stepTextViewInsets = LayoutInsets(top: 16, left: 16, bottom: 4, right: 16)
    }

    enum Animation {
        static let appearanceAnimationDuration: TimeInterval = 0.25
        static let appearanceAnimationDelay: TimeInterval = 0.3
    }
}

final class CodeQuizFullscreenInstructionView: UIView {
    let appearance: Appearance
    weak var delegate: CodeQuizFullscreenInstructionViewDelegate?

    private lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let loadingIndicatorView = UIActivityIndicatorView(style: .stepikWhiteLarge)
        loadingIndicatorView.color = self.appearance.loadingIndicatorColor
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.startAnimating()
        return loadingIndicatorView
    }()

    private lazy var scrollableStackView: ScrollableStackView = {
        let view = ScrollableStackView(orientation: .vertical)
        view.spacing = self.appearance.spacing
        return view
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

    // MARK: Public API

    func startLoading() {
        self.scrollableStackView.alpha = 0.0
        self.loadingIndicatorView.startAnimating()
    }

    func endLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Animation.appearanceAnimationDelay) {
            self.loadingIndicatorView.stopAnimating()

            UIView.animate(
                withDuration: Animation.appearanceAnimationDuration,
                animations: {
                    self.scrollableStackView.alpha = 1.0
                }
            )
        }
    }

    func configure(htmlString: String, samples: [CodeSamplePlainObject], limit: CodeLimitPlainObject) {
        self.scrollableStackView.removeAllArrangedViews()

        var stepTextViewAppearance = ProcessedContentView.Appearance()
        stepTextViewAppearance.insets = self.appearance.stepTextViewInsets
        let stepTextView = ProcessedContentView(appearance: stepTextViewAppearance)
        stepTextView.delegate = self
        self.scrollableStackView.addArrangedView(stepTextView)
        stepTextView.processedContent = .html(htmlString)

        let isEmptyDetails = samples.isEmpty && limit.memory == 0 && limit.time == 0
        if !isEmptyDetails {
            let detailsContentView = CodeDetailsContentView()
            self.scrollableStackView.addArrangedView(detailsContentView)
            detailsContentView.configure(samples: samples, limit: limit)
        }
    }
}

extension CodeQuizFullscreenInstructionView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.scrollableStackView)
        self.addSubview(self.loadingIndicatorView)
    }

    func makeConstraints() {
        self.scrollableStackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollableStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.top.bottom.equalToSuperview()
        }

        self.loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

extension CodeQuizFullscreenInstructionView: ProcessedContentViewDelegate {
    func processedContentViewDidLoadContent(_ view: ProcessedContentView) {
        self.delegate?.codeQuizFullscreenInstructionViewDidLoadContent(self)
    }

    func processedContentView(_ view: ProcessedContentView, didReportNewHeight height: Int) {
        self.layoutIfNeeded()
        self.invalidateIntrinsicContentSize()
    }

    func processedContentView(_ view: ProcessedContentView, didOpenImageURL url: URL) {
        self.delegate?.codeQuizFullscreenInstructionView(self, didRequestFullscreenImage: url)
    }

    func processedContentView(_ view: ProcessedContentView, didOpenLink url: URL) {
        self.delegate?.codeQuizFullscreenInstructionView(self, didRequestOpenURL: url)
    }
}
