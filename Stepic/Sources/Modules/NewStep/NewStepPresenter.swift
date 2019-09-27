import PromiseKit
import UIKit

protocol NewStepPresenterProtocol {
    func presentStep(response: NewStep.StepLoad.Response)
    func presentControlsUpdate(response: NewStep.ControlsUpdate.Response)
}

final class NewStepPresenter: NewStepPresenterProtocol {
    weak var viewController: NewStepViewControllerProtocol?

    func presentStep(response: NewStep.StepLoad.Response) {
        if case .success(let data) = response.result {
            self.makeViewModel(
                step: data.step,
                fontSize: data.fontSize
            ).done(on: .global(qos: .userInitiated)) { viewModel in
                DispatchQueue.main.async { [weak self] in
                    self?.viewController?.displayStep(
                        viewModel: NewStep.StepLoad.ViewModel(state: .result(data: viewModel))
                    )
                }
            }

            return
        }

        if case .failure = response.result {
            self.viewController?.displayStep(viewModel: NewStep.StepLoad.ViewModel(state: .error))
        }
    }

    func presentControlsUpdate(response: NewStep.ControlsUpdate.Response) {
        let viewModel = NewStep.ControlsUpdate.ViewModel(
            canNavigateToPreviousUnit: response.canNavigateToPreviousUnit,
            canNavigateToNextUnit: response.canNavigateToNextUnit,
            canNavigateToNextStep: response.canNavigateToNextStep
        )

        self.viewController?.displayControlsUpdate(viewModel: viewModel)
    }

    // MARK: Private API

    private func makeViewModel(step: Step, fontSize: FontSize) -> Guarantee<NewStepViewModel> {
        return Guarantee { seal in
            let discussionsLabelTitle: String = {
                if let discussionsCount = step.discussionsCount, discussionsCount > 0 {
                    return String(
                        format: NSLocalizedString("DiscussionsButtonTitle", comment: ""),
                        FormatterHelper.longNumber(discussionsCount)
                    )
                }
                return NSLocalizedString("NoDiscussionsButtonTitle", comment: "")
            }()

            let contentType: NewStepViewModel.ContentType = {
                switch step.block.name {
                case "video":
                    if let video = step.block.video {
                        let viewModel = NewStepVideoViewModel(
                            video: video,
                            videoThumbnailImageURL: URL(string: video.thumbnailURL)
                        )
                        return .video(viewModel: viewModel)
                    }
                    return .video(viewModel: nil)
                default:
                    var injections = ContentProcessor.defaultInjections
                    injections.append(FontSizeInjection(fontSize: fontSize))

                    let contentProcessor = ContentProcessor(
                        content: step.block.text ?? "",
                        rules: ContentProcessor.defaultRules,
                        injections: injections
                    )
                    let content = contentProcessor.processContent()

                    return .text(htmlString: content)
                }
            }()

            let quizType: NewStep.QuizType?
            switch step.block.name {
            case "text", "video":
                quizType = nil
            default:
                quizType = NewStep.QuizType(blockName: step.block.name)
            }

            let urlPath = "\(StepicApplicationsInfo.stepicURL)/lesson/\(step.lessonId)/step/\(step.position)?from_mobile_app=true"

            let viewModel = NewStepViewModel(
                content: contentType,
                quizType: quizType,
                discussionsLabelTitle: discussionsLabelTitle,
                discussionProxyID: step.discussionProxyId,
                stepURLPath: urlPath,
                lessonID: step.lessonId,
                step: step
            )
            seal(viewModel)
        }
    }
}
