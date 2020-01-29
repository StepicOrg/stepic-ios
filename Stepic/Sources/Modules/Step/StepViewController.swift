import Agrume
import UIKit

protocol StepViewControllerProtocol: AnyObject {
    func displayStep(viewModel: StepDataFlow.StepLoad.ViewModel)
    func displayStepTextUpdate(viewModel: StepDataFlow.StepTextUpdate.ViewModel)
    func displayPlayStep(viewModel: StepDataFlow.PlayStep.ViewModel)
    func displayControlsUpdate(viewModel: StepDataFlow.ControlsUpdate.ViewModel)
    func displayDiscussionsButtonUpdate(viewModel: StepDataFlow.DiscussionsButtonUpdate.ViewModel)
    func displayDiscussions(viewModel: StepDataFlow.DiscussionsPresentation.ViewModel)
}

// MARK: - StepViewController (Animation) -

extension StepViewController {
    enum Animation {
        static let autoplayVideoPlayerPresentationDelay: TimeInterval = 0.75
    }
}

// MARK: - StepViewController: UIViewController, ControllerWithStepikPlaceholder -

final class StepViewController: UIViewController, ControllerWithStepikPlaceholder {
    private static let stepPassedDelay: TimeInterval = 1.0

    lazy var stepView = self.view as? StepView

    var placeholderContainer = StepikPlaceholderControllerContainer()

    private let interactor: StepInteractorProtocol

    private var state: StepDataFlow.ViewControllerState {
        didSet {
            self.updateState()
        }
    }

    private var didInitRequestsSend = false
    private var sendStepDidPassedGroup: DispatchGroup? = DispatchGroup()

    private var isFirstAppearance = true

    private var canNavigateToNextStep = false
    /// Keeps track of need to autoplay the step or not.
    private var shouldRequestAutoplay = false

    init(interactor: StepInteractorProtocol) {
        self.interactor = interactor
        self.state = .loading
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = StepView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.registerPlaceholder(
            placeholder: StepikPlaceholder(
                .noConnectionQuiz,
                action: { [weak self] in
                    self?.interactor.doStepLoad(request: .init())
                }
            ),
            for: .connectionError
        )

        self.stepView?.delegate = self

        // Enter group, leave when content did load & in view did appear
        self.sendStepDidPassedGroup?.enter()
        self.sendStepDidPassedGroup?.enter()

        self.updateState()
        self.sendStepDidPassedGroup?.notify(queue: .main) { [weak self] in
            self?.sendStepDidPassedGroup = nil
            self?.sendInitStepStatusRequests()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isFirstAppearance {
            self.interactor.doDiscussionsButtonUpdate(request: .init())
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        defer {
            self.isFirstAppearance = false
        }

        // TODO: Move this request to viewDidLoad, but we should deal with WKWebView behavior before
        if self.isFirstAppearance {
            self.interactor.doStepLoad(request: .init())
        }

        if !self.didInitRequestsSend {
            self.sendStepDidPassedGroup?.leave()
        }

        self.requestAutoplayIfNeeded()
    }

    // MARK: Private API

    private func updateState() {
        switch self.state {
        case .result:
            self.isPlaceholderShown = false
            self.showContent()
        case .loading:
            self.isPlaceholderShown = false
            self.stepView?.startLoading()
        case .error:
            self.showPlaceholder(for: .connectionError)
        }
    }

    private func sendInitStepStatusRequests() {
        defer {
            self.didInitRequestsSend = true
        }

        self.interactor.doStepViewRequest(request: .init())

        guard case .result(let viewModel) = self.state, viewModel.quizType == nil else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + StepViewController.stepPassedDelay) { [weak self] in
            self?.interactor.doStepDoneRequest(request: .init())
        }
    }

    @objc
    private func showContent() {
        guard case .result(let viewModel) = self.state else {
            return
        }

        if !self.didInitRequestsSend {
            self.sendStepDidPassedGroup?.leave()
        }

        guard let quizType = viewModel.quizType else {
            // Video & text steps
            self.stepView?.configure(viewModel: viewModel, quizView: nil)
            self.requestAutoplayIfNeeded()
            return
        }

        let quizController: UIViewController? = {
            switch quizType {
            case .string, .number, .math, .freeAnswer, .choice, .code, .sql, .sorting, .matching:
                let assembly = BaseQuizAssembly(
                    step: viewModel.step,
                    hasNextStep: self.canNavigateToNextStep,
                    output: self
                )
                return assembly.makeModule()
            default:
                return nil
            }
        }()

        if let controller = quizController {
            self.addChild(controller)
            self.stepView?.configure(viewModel: viewModel, quizView: controller.view)
        } else {
            let assembly = UnsupportedQuizAssembly(stepURLPath: viewModel.stepURLPath)
            let viewController = assembly.makeModule()
            self.addChild(viewController)
            self.stepView?.configure(viewModel: viewModel, quizView: viewController.view)
        }
    }

    private func requestAutoplayIfNeeded() {
        guard self.shouldRequestAutoplay,
              case .result = self.state else {
            return
        }

        self.shouldRequestAutoplay = false

        DispatchQueue.main.asyncAfter(deadline: .now() + Animation.autoplayVideoPlayerPresentationDelay) {
            self.presentVideoPlayer()
        }
    }
}

// MARK: - StepViewController: StepViewControllerProtocol -

extension StepViewController: StepViewControllerProtocol {
    func displayStep(viewModel: StepDataFlow.StepLoad.ViewModel) {
        self.state = viewModel.state
    }

    func displayStepTextUpdate(viewModel: StepDataFlow.StepTextUpdate.ViewModel) {
        self.stepView?.updateText(viewModel.htmlText)
    }

    func displayPlayStep(viewModel: StepDataFlow.PlayStep.ViewModel) {
        self.shouldRequestAutoplay = true
        self.requestAutoplayIfNeeded()
    }

    func displayControlsUpdate(viewModel: StepDataFlow.ControlsUpdate.ViewModel) {
        self.stepView?.updateNavigationButtons(
            hasPreviousButton: viewModel.canNavigateToPreviousUnit,
            hasNextButton: viewModel.canNavigateToNextUnit
        )
        self.canNavigateToNextStep = viewModel.canNavigateToNextStep
    }

    func displayDiscussionsButtonUpdate(viewModel: StepDataFlow.DiscussionsButtonUpdate.ViewModel) {
        self.stepView?.updateDiscussionButton(title: viewModel.title, isEnabled: viewModel.isEnabled)
    }

    func displayDiscussions(viewModel: StepDataFlow.DiscussionsPresentation.ViewModel) {
        let discussionsAssembly = DiscussionsAssembly(
            discussionProxyID: viewModel.discussionProxyID,
            stepID: viewModel.stepID
        )
        let discussionsViewController = discussionsAssembly.makeModule()

        if viewModel.embeddedInWriteComment {
            let (modalPresentationStyle, navigationBarAppearance) = {
                () -> (UIModalPresentationStyle, StyledNavigationController.NavigationBarAppearanceState) in
                if #available(iOS 13.0, *) {
                    return (
                        .automatic,
                        .init(
                            statusBarColor: .clear,
                            statusBarStyle: .lightContent
                        )
                    )
                } else {
                    return (.fullScreen, .init())
                }
            }()

            let writeCommentAssembly = WriteCommentAssembly(
                targetID: viewModel.stepID,
                parentID: nil,
                presentationContext: .create,
                navigationBarAppearance: navigationBarAppearance,
                output: discussionsAssembly.moduleInput
            )
            let writeCommentNavigationController = StyledNavigationController(
                rootViewController: writeCommentAssembly.makeModule()
            )
            writeCommentNavigationController.modalPresentationStyle = modalPresentationStyle

            self.navigationController?.present(
                writeCommentNavigationController,
                animated: true,
                completion: { [weak self] in
                    guard let strongSelf = self,
                          let navigationController = strongSelf.navigationController else {
                        return
                    }

                    navigationController.setViewControllers(
                        navigationController.viewControllers + [discussionsViewController],
                        animated: false
                    )
                }
            )
        } else {
            self.push(module: discussionsViewController)
        }
    }
}

// MARK: - StepViewController: StepViewDelegate -

extension StepViewController: StepViewDelegate {
    func stepViewDidRequestVideo(_ view: StepView) {
        self.presentVideoPlayer()
    }

    func stepViewDidRequestPrevious(_ view: StepView) {
        self.interactor.doLessonNavigationRequest(request: .init(direction: .previous))
    }

    func stepViewDidRequestNext(_ view: StepView) {
        self.interactor.doLessonNavigationRequest(request: .init(direction: .next))
    }

    func stepViewDidRequestDiscussions(_ view: StepView) {
        self.interactor.doDiscussionsPresentation(request: .init())
    }

    func stepView(_ view: StepView, didRequestOpenURL url: URL) {
        guard case .result(let viewModel) = self.state else {
            return
        }

        // Check if the request is a navigation inside a lesson
        if url.absoluteString.contains("\(viewModel.lessonID)/step/") {
            let components = url.pathComponents
            if let index = components.firstIndex(of: "step") {
                if index + 1 < components.count {
                    let urlStepIndexString = components[index + 1]
                    if let urlStepIndex = Int(urlStepIndexString) {
                        self.interactor.doStepNavigationRequest(request: .init(direction: .index(urlStepIndex - 1)))
                        return
                    }
                }
            }
        }

        WebControllerManager.sharedManager.presentWebControllerWithURL(
            url,
            inController: self,
            withKey: "external link",
            allowsSafari: true,
            backButtonStyle: .done
        )
    }

    func stepView(_ view: StepView, didRequestFullscreenImage url: URL) {
        let agrume = Agrume(url: url)
        agrume.show(from: self)
    }

    func stepView(_ view: StepView, didRequestFullscreenImage image: UIImage) {
        let agrume = Agrume(image: image)
        agrume.show(from: self)
    }

    func stepViewDidLoadContent(_ view: StepView) {
        self.stepView?.endLoading()
    }

    // MARK: Private helpers

    private func presentVideoPlayer() {
        guard case .result(let viewModel) = self.state,
              case .video(let videoViewModel) = viewModel.content,
              let video = videoViewModel?.video else {
            return
        }

        let isVideoPlayingReachable = ConnectionHelper.shared.reachability.isReachableViaWiFi()
            || ConnectionHelper.shared.reachability.isReachableViaWWAN()
        let isVideoCached = video.state == .cached

        if !isVideoCached && !isVideoPlayingReachable {
            let alert = UIAlertController(
                title: NSLocalizedString("StepVideoPlayingNotReachableErrorTitle", comment: ""),
                message: NSLocalizedString("StepVideoPlayingNotReachableErrorMessage", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if isVideoCached || isVideoPlayingReachable {
            let assembly = StepikVideoPlayerLegacyAssembly(video: video, delegate: self)
            AnalyticsReporter.reportEvent(AnalyticsEvents.VideoPlayer.opened, parameters: nil)
            self.present(module: assembly.makeModule(), embedInNavigation: false, modalPresentationStyle: .fullScreen)
        }
    }
}

// MARK: - StepViewController: BaseQuizOutputProtocol -

extension StepViewController: BaseQuizOutputProtocol {
    func handleCorrectSubmission() {
        self.interactor.doStepDoneRequest(request: .init())
    }

    func handleNextStepNavigation() {
        self.interactor.doStepNavigationRequest(request: .init(direction: .next))
    }
}

// MARK: - StepViewController: StepikVideoPlayerViewControllerDelegate -

extension StepViewController: StepikVideoPlayerViewControllerDelegate {
    func stepikVideoPlayerViewControllerDidRequestAutoplay() {
        self.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.interactor.doAutoplayNavigationRequest(request: .init())
            }
        )
    }
}