import Foundation

enum CourseInfo {
    enum Tab {
        case info
        case syllabus
        case reviews

        var title: String {
            switch self {
            case .info:
                return NSLocalizedString("CourseInfoTabInfo", comment: "")
            case .syllabus:
                return NSLocalizedString("CourseInfoTabSyllabus", comment: "")
            case .reviews:
                return NSLocalizedString("CourseInfoTabReviews", comment: "")
            }
        }
    }

    // MARK: Use cases

    /// Load & show info about course
    enum CourseLoad {
        struct Request { }

        struct Response {
            var result: StepikResult<Course>
        }

        struct ViewModel {
            var state: ViewControllerState
        }
    }

    /// Register submodules
    enum SubmoduleRegistration {
        struct Request {
            var submodules: [Int: CourseInfoSubmoduleProtocol]
        }
    }

    /// Show lesson
    enum LessonPresentation {
        struct Response {
            let unitID: Unit.IdType
        }

        struct ViewModel {
            let unitID: Unit.IdType
        }
    }

    /// Show personal deadlines create / edit & delete action
    enum PersonalDeadlinesSettingsPresentation {
        enum Action {
            case create
            case edit
        }

        struct Response {
            let action: Action

            @available(*, deprecated, message: "Should containts only course ID")
            let course: Course
        }

        struct ViewModel {
            let action: Action

            @available(*, deprecated, message: "Should containts only course ID")
            let course: Course
        }
    }

    /// Present exam in web
    enum ExamLessonPresentation {
        struct Response {
            let urlPath: String
        }

        struct ViewModel {
            let urlPath: String
        }
    }

    /// Share course
    enum CourseShareAction {
        struct Request { }

        struct Response {
            let urlPath: String
        }

        struct ViewModel {
            let urlPath: String
        }
    }

    /// Present last step in course
    enum LastStepPresentation {
        struct Response {
            let course: Course
            let isAdaptive: Bool
        }

        struct ViewModel {
            @available(*, deprecated, message: "Target modules can't be initialized w/o model")
            let course: Course
            @available(*, deprecated, message: "Target modules can't be initialized w/o model")
            let isAdaptive: Bool
        }
    }

    /// Handle submodule controller appearance
    enum SubmoduleAppearanceUpdate {
        struct Request {
            let submoduleIndex: Int
        }
    }

    /// Handle HUD
    enum BlockingWaitingIndicatorUpdate {
        struct Response {
            let shouldDismiss: Bool
        }

        struct ViewModel {
            let shouldDismiss: Bool
        }
    }

    /// Drop course
    enum CourseUnenrollmentAction {
        struct Request { }
    }

    /// Do main action (continue, enroll, etc)
    enum MainCourseAction {
        struct Request { }
    }

    /// Try to set online mode
    enum OnlineModeReset {
        struct Request { }
    }

    /// Register for remote notifications
    enum RemoteNotificationsRegistration {
        struct Request { }
    }

    /// Present authorization controller
    enum AuthorizationPresentation {
        struct Response { }

        struct ViewModel { }
    }

    /// Present web view for paid course
    enum PaidCourseBuyingPresentation {
        struct Response {
            let course: Course
        }

        struct ViewModel {
            let urlPath: String
        }
    }

    // MARK: States

    enum ViewControllerState {
        case loading
        case result(data: CourseInfoHeaderViewModel)
    }
}
