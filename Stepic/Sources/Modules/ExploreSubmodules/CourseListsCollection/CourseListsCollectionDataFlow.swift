import Foundation

enum CourseListsCollection {
    // MARK: Use cases

    /// Show course lists
    enum CourseListsLoad {
        struct Request { }

        struct Response {
            var result: StepikResult<[CourseListModel]>
        }

        struct ViewModel {
            var state: ViewControllerState
        }
    }

    /// Present collection in fullscreen
    enum FullscreenCourseListModulePresentation {
        struct Request {
            let presentationDescription: CourseList.PresentationDescription
            let courseListType: CourseListType
        }
    }

    // MARK: States

    enum ViewControllerState {
        case loading
        case result(data: [CourseListsCollectionViewModel])
    }
}
