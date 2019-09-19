import UIKit

protocol CourseInfoPresenterProtocol {
    func presentCourse(response: CourseInfo.CourseLoad.Response)
    func presentLesson(response: CourseInfo.LessonPresentation.Response)
    func presentPersonalDeadlinesSettings(response: CourseInfo.PersonalDeadlinesSettingsPresentation.Response)
    func presentExamLesson(response: CourseInfo.ExamLessonPresentation.Response)
    func presentCourseSharing(response: CourseInfo.CourseShareAction.Response)
    func presentLastStep(response: CourseInfo.LastStepPresentation.Response)
    func presentAuthorization(response: CourseInfo.AuthorizationPresentation.Response)
    func presentWaitingState(response: CourseInfo.BlockingWaitingIndicatorUpdate.Response)
    func presentPaidCourseBuying(response: CourseInfo.PaidCourseBuyingPresentation.Response)
}

final class CourseInfoPresenter: CourseInfoPresenterProtocol {
    weak var viewController: CourseInfoViewControllerProtocol?

    func presentCourse(response: CourseInfo.CourseLoad.Response) {
        switch response.result {
        case .success(let result):
            let viewModel = CourseInfo.CourseLoad.ViewModel(
                state: .result(data: self.makeHeaderViewModel(course: result))
            )
            self.viewController?.displayCourse(viewModel: viewModel)
        default:
            break
        }
    }

    func presentLesson(response: CourseInfo.LessonPresentation.Response) {
        let initObjects: LessonInitObjects = (
            lesson: response.lesson,
            startStepId: 0,
            context: .unit
        )

        let initIDs: LessonInitIds = (
            stepId: nil,
            unitId: response.unitID
        )

        let viewModel = CourseInfo.LessonPresentation.ViewModel(
            unitID: response.unitID,
            initObjects: initObjects,
            initIDs: initIDs
        )

        self.viewController?.displayLesson(viewModel: viewModel)
    }

    func presentPersonalDeadlinesSettings(response: CourseInfo.PersonalDeadlinesSettingsPresentation.Response) {
        let viewModel = CourseInfo.PersonalDeadlinesSettingsPresentation.ViewModel(
            action: response.action,
            course: response.course
        )
        self.viewController?.displayPersonalDeadlinesSettings(viewModel: viewModel)
    }

    func presentExamLesson(response: CourseInfo.ExamLessonPresentation.Response) {
        let viewModel = CourseInfo.ExamLessonPresentation.ViewModel(
            urlPath: response.urlPath
        )
        self.viewController?.displayExamLesson(viewModel: viewModel)
    }

    func presentCourseSharing(response: CourseInfo.CourseShareAction.Response) {
        let viewModel = CourseInfo.CourseShareAction.ViewModel(
            urlPath: response.urlPath
        )
        self.viewController?.displayCourseSharing(viewModel: viewModel)
    }

    func presentWaitingState(response: CourseInfo.BlockingWaitingIndicatorUpdate.Response) {
        self.viewController?.displayBlockingLoadingIndicator(viewModel: .init(shouldDismiss: response.shouldDismiss))
    }

    func presentLastStep(response: CourseInfo.LastStepPresentation.Response) {
        self.viewController?.displayLastStep(
            viewModel: .init(
                course: response.course,
                isAdaptive: response.isAdaptive
            )
        )
    }

    func presentAuthorization(response: CourseInfo.AuthorizationPresentation.Response) {
        self.viewController?.displayAuthorization(viewModel: .init())
    }

    func presentPaidCourseBuying(response: CourseInfo.PaidCourseBuyingPresentation.Response) {
        let path = "https://stepik.org/course/\(response.course.id)"
        self.viewController?.displayPaidCourseBuying(viewModel: .init(urlPath: path))
    }

    private func makeProgressViewModel(progress: Progress) -> CourseInfoProgressViewModel {
        var normalizedPercent = progress.percentPassed
        normalizedPercent.round(.up)

        return CourseInfoProgressViewModel(
            progress: normalizedPercent / 100.0,
            progressLabelText: "\(progress.score)/\(progress.cost)"
        )
    }

    private func makeHeaderViewModel(course: Course) -> CourseInfoHeaderViewModel {
        let rating: Int = {
            if let reviewsCount = course.reviewSummary?.count,
               let averageRating = course.reviewSummary?.average,
               reviewsCount > 0 {
                return Int(round(averageRating))
            }
            return 0
        }()

        let progress: CourseInfoProgressViewModel? = {
            if let progress = course.progress {
                return self.makeProgressViewModel(progress: progress)
            }
            return nil
        }()

        return CourseInfoHeaderViewModel(
            title: course.title,
            coverImageURL: URL(string: course.coverURLString),
            rating: rating,
            learnersLabelText: FormatterHelper.longNumber(course.learnersCount ?? 0),
            progress: progress,
            isVerified: (course.readiness ?? 0) > 0.9,
            isEnrolled: course.enrolled,
            buttonDescription: self.makeButtonDescription(course: course)
        )
    }

    private func makeButtonDescription(course: Course) -> CourseInfoHeaderViewModel.ButtonDescription {
        let isEnrolled = course.enrolled
        let isEnabled = isEnrolled ? course.canContinue : true
        let title: String = {
            if isEnrolled {
                return NSLocalizedString("WidgetButtonLearn", comment: "")
            }

            if course.isPaid, let displayPrice = course.displayPrice {
                return String(format: NSLocalizedString("WidgetButtonBuy", comment: ""), displayPrice)
            }

            return NSLocalizedString("WidgetButtonJoin", comment: "")
        }()

        return CourseInfoHeaderViewModel.ButtonDescription(
            title: title,
            isCallToAction: !isEnrolled,
            isEnabled: isEnabled
        )
    }
}
