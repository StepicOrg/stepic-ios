import Foundation

enum BaseQuiz {
    /// Load latest submission for existing attempt or load new one
    enum SubmissionLoad {
        struct Data {
            let step: Step
            let attempt: Attempt
            let submission: Submission
            let submissionsCount: Int
            let hasNextStep: Bool
        }

        struct Request {
            let shouldRefreshAttempt: Bool
        }

        struct Response {
            let result: StepikResult<Data>
        }

        struct ViewModel {
            let state: ViewControllerState
        }
    }

    /// Submit quiz
    enum SubmissionSubmit {
        struct Request {
            let reply: Reply
        }
    }

    /// Cache reply
    enum ReplyCache {
        struct Request {
            let reply: Reply
        }
    }

    /// Present rate app alert
    enum RateAppAlertPresentation {
        struct Response {}

        struct ViewModel {}
    }

    /// Present streak alert
    enum StreakAlertPresentation {
        struct Response {
            let streak: Int
        }

        struct ViewModel {
            let streak: Int
        }
    }

    /// Navigate to next step  inside lesson
    enum NextStepNavigation {
        struct Request {}
    }

    enum ViewControllerState {
        case loading
        case result(data: BaseQuizViewModel)
        case error
    }
}
