import UIKit

protocol SolutionPresenterProtocol {
    func presentSolution(response: Solution.SolutionLoad.Response)
}

final class SolutionPresenter: SolutionPresenterProtocol {
    weak var viewController: SolutionViewControllerProtocol?

    func presentSolution(response: Solution.SolutionLoad.Response) {
        switch response.result {
        case .failure:
            self.viewController?.displaySolution(viewModel: .init(state: .error))
        case .success(let data):
            let viewModel = self.makeViewModel(
                step: data.step,
                submission: data.submission,
                submissionURL: data.submissionURL
            )
            self.viewController?.displaySolution(viewModel: .init(state: .result(data: viewModel)))
        }
    }

    private func makeViewModel(
        step: Step,
        submission: Submission,
        submissionURL: URL?
    ) -> SolutionViewModel {
        let quizStatus = QuizStatus(submission: submission) ?? .wrong

        let feedbackTitle = self.makeFeedbackTitle(status: quizStatus)

        let hintContent: String? = {
            if let text = submission.hint, !text.isEmpty {
                return self.makeHintContent(text: text)
            }
            return nil
        }()

        let codeDetails: CodeDetails? = {
            if let options = step.options {
                return CodeDetails(
                    stepID: step.id,
                    stepContent: step.block.text ?? "",
                    stepOptions: StepOptionsPlainObject(stepOptions: options)
                )
            }
            return nil
        }()

        return SolutionViewModel(
            step: step,
            quizStatus: quizStatus,
            reply: submission.reply,
            dataset: submission.attempt?.dataset,
            feedback: submission.feedback,
            feedbackTitle: feedbackTitle,
            hintContent: hintContent,
            codeDetails: codeDetails,
            solutionURL: submissionURL
        )
    }

    private func makeFeedbackTitle(status: QuizStatus) -> String {
        switch status {
        case .correct:
            let correctTitles = [
                NSLocalizedString("CorrectFeedbackTitle1", comment: ""),
                NSLocalizedString("CorrectFeedbackTitle3", comment: ""),
                NSLocalizedString("CorrectFeedbackTitle4", comment: ""),
                NSLocalizedString("CorrectFeedbackTitle9", comment: ""),
                NSLocalizedString("CorrectFeedbackTitle11", comment: "")
            ]

            return correctTitles.randomElement() ?? NSLocalizedString("Correct", comment: "")
        case .partiallyCorrect:
            return NSLocalizedString("PartiallyCorrectFeedbackTitle1", comment: "")
        case .wrong:
            return NSLocalizedString("WrongFeedbackTitleLastTry", comment: "")
        case .evaluation:
            return NSLocalizedString("EvaluationFeedbackTitle", comment: "")
        }
    }

    private func makeHintContent(text: String) -> String {
        /// Use <pre> tag with text wrapping for feedback
        let text = "<div style=\"white-space: pre-wrap;\">\(text)</div>"

        let injections = ContentProcessor.defaultInjections + [
            TextColorInjection(dynamicColor: .stepikPrimaryText)
        ]

        let contentProcessor = ContentProcessor(
            rules: ContentProcessor.defaultRules,
            injections: injections
        )

        let processedContent = contentProcessor.processContent(text)

        return processedContent.stringValue
    }
}
