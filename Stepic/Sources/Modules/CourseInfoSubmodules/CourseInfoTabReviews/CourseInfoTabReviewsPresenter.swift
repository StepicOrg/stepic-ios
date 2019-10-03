import Foundation

protocol CourseInfoTabReviewsPresenterProtocol: class {
    func presentCourseReviews(response: CourseInfoTabReviews.ReviewsLoad.Response)
    func presentNextCourseReviews(response: CourseInfoTabReviews.NextReviewsLoad.Response)
    func presentWriteCourseReview(response: CourseInfoTabReviews.WriteCourseReviewPresentation.Response)
}

final class CourseInfoTabReviewsPresenter: CourseInfoTabReviewsPresenterProtocol {
    weak var viewController: CourseInfoTabReviewsViewControllerProtocol?

    func presentCourseReviews(response: CourseInfoTabReviews.ReviewsLoad.Response) {
        let viewModel: CourseInfoTabReviews.ReviewsLoad.ViewModel = .init(
            state: CourseInfoTabReviews.ViewControllerState.result(
                data: .init(
                    reviews: response.reviews.compactMap { self.makeViewModel(courseReview: $0) },
                    hasNextPage: response.hasNextPage,
                    writeCourseReviewState: self.getWriteCourseReviewState(
                        course: response.course,
                        reviews: response.reviews,
                        currentUserReview: response.currentUserReview
                    )
                )
            )
        )
        self.viewController?.displayCourseReviews(viewModel: viewModel)
    }

    func presentNextCourseReviews(response: CourseInfoTabReviews.NextReviewsLoad.Response) {
        let viewModel: CourseInfoTabReviews.NextReviewsLoad.ViewModel = .init(
            state: CourseInfoTabReviews.PaginationState.result(
                data: .init(
                    reviews: response.reviews.compactMap { self.makeViewModel(courseReview: $0) },
                    hasNextPage: response.hasNextPage,
                    writeCourseReviewState: self.getWriteCourseReviewState(
                        course: response.course,
                        reviews: response.reviews,
                        currentUserReview: response.currentUserReview
                    )
                )
            )
        )
        self.viewController?.displayNextCourseReviews(viewModel: viewModel)
    }

    func presentWriteCourseReview(response: CourseInfoTabReviews.WriteCourseReviewPresentation.Response) {
        self.viewController?.displayWriteCourseReview(
            viewModel: CourseInfoTabReviews.WriteCourseReviewPresentation.ViewModel(
                courseID: response.course.id,
                review: response.review
            )
        )
    }

    private func makeViewModel(courseReview: CourseReview) -> CourseInfoTabReviewsViewModel? {
        guard let reviewAuthor = courseReview.user else {
            return nil
        }

        return CourseInfoTabReviewsViewModel(
            userName: reviewAuthor.fullName,
            dateRepresentation: FormatterHelper.dateStringWithFullMonthAndYear(courseReview.creationDate),
            text: courseReview.text.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarImageURL: URL(string: reviewAuthor.avatarURL),
            score: courseReview.score
        )
    }

    private func getWriteCourseReviewState(
        course: Course,
        reviews: [CourseReview],
        currentUserReview: CourseReview?
    ) -> CourseInfoTabReviews.WriteCourseReviewState {
        if course.progressId == nil {
            return .hide
        }

        if currentUserReview != nil {
            return .edit
        }

        return course.canWriteReview
            ? .write
            : .banner(NSLocalizedString("WriteCourseReviewActionNotAllowedDescription", comment: ""))
    }
}
