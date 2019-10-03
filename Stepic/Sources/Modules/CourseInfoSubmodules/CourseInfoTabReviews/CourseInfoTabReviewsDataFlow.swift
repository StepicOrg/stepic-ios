import Foundation

enum CourseInfoTabReviews {
    // MARK: Common structs

    struct ReviewsResult {
        let reviews: [CourseInfoTabReviewsViewModel]
        let hasNextPage: Bool
        let writeCourseReviewState: WriteCourseReviewState
    }

    // MARK: Use cases

    /// Show reviews
    enum ReviewsLoad {
        struct Request { }

        struct Response {
            let course: Course
            let reviews: [CourseReview]
            let hasNextPage: Bool
        }

        struct ViewModel {
            let state: ViewControllerState
        }
    }

    /// Load next part reviews
    enum NextReviewsLoad {
        struct Request { }

        struct Response {
            let course: Course
            let reviews: [CourseReview]
            let hasNextPage: Bool
        }

        struct ViewModel {
            let state: PaginationState
        }
    }

    // MARK: States

    enum ViewControllerState {
        case loading
        case result(data: ReviewsResult)
    }

    enum PaginationState {
        case result(data: ReviewsResult)
        case error(message: String)
    }

    enum WriteCourseReviewState {
        case write
        case hide
        case banner(String)
    }
}
