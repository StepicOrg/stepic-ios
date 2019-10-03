import UIKit

protocol CourseInfoTabReviewsViewControllerProtocol: class {
    func displayCourseReviews(viewModel: CourseInfoTabReviews.ReviewsLoad.ViewModel)
    func displayNextCourseReviews(viewModel: CourseInfoTabReviews.NextReviewsLoad.ViewModel)
    func displayWriteCourseReview(viewModel: CourseInfoTabReviews.WriteCourseReviewPresentation.ViewModel)
}

final class CourseInfoTabReviewsViewController: UIViewController {
    private let interactor: CourseInfoTabReviewsInteractorProtocol

    lazy var courseInfoTabReviewsView = self.view as? CourseInfoTabReviewsView

    private lazy var paginationView = PaginationView()

    private var state: CourseInfoTabReviews.ViewControllerState
    private var canTriggerPagination = true

    private let tableDataSource = CourseInfoTabReviewsTableViewDataSource()

    init(
        interactor: CourseInfoTabReviewsInteractorProtocol,
        initialState: CourseInfoTabReviews.ViewControllerState = .loading
    ) {
        self.interactor = interactor
        self.state = initialState
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateState(newState: self.state)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = CourseInfoTabReviewsView()
        view.paginationView = self.paginationView
        view.delegate = self

        self.view = view
    }

    private func updatePagination(hasNextPage: Bool, hasError: Bool) {
        self.canTriggerPagination = hasNextPage
        if hasNextPage {
            self.paginationView.setLoading()
            self.courseInfoTabReviewsView?.showPaginationView()
        } else {
            self.courseInfoTabReviewsView?.hidePaginationView()
        }
    }

    private func updateState(newState: CourseInfoTabReviews.ViewControllerState) {
        defer {
            self.state = newState
        }

        if case .loading = newState {
            self.courseInfoTabReviewsView?.showLoading()
            return
        }

        if case .loading = self.state {
            self.courseInfoTabReviewsView?.hideLoading()
        }

        if case .result(let data) = newState {
            self.courseInfoTabReviewsView?.updateTableViewData(dataSource: self.tableDataSource)
            self.courseInfoTabReviewsView?.writeCourseReviewState = data.writeCourseReviewState
        }
    }
}

// MARK: - CourseInfoTabReviewsViewController: CourseInfoTabReviewsViewControllerProtocol -

extension CourseInfoTabReviewsViewController: CourseInfoTabReviewsViewControllerProtocol {
    func displayCourseReviews(viewModel: CourseInfoTabReviews.ReviewsLoad.ViewModel) {
        if case .result(let data) = viewModel.state {
            self.tableDataSource.viewModels = data.reviews
            self.updateState(newState: viewModel.state)
            self.updatePagination(hasNextPage: data.hasNextPage, hasError: false)
        }
    }

    func displayNextCourseReviews(viewModel: CourseInfoTabReviews.NextReviewsLoad.ViewModel) {
        switch viewModel.state {
        case .result(let data):
            self.tableDataSource.viewModels.append(contentsOf: data.reviews)
            self.updateState(newState: self.state)
            self.updatePagination(hasNextPage: data.hasNextPage, hasError: false)
        case .error:
            self.updateState(newState: self.state)
            self.updatePagination(hasNextPage: false, hasError: true)
        }
    }

    func displayWriteCourseReview(viewModel: CourseInfoTabReviews.WriteCourseReviewPresentation.ViewModel) {
        let assembly = WriteCourseReviewAssembly(
            courseID: viewModel.courseID,
            courseReview: viewModel.review,
            output: self.interactor as? WriteCourseReviewOutputProtocol
        )
        let controller = StyledNavigationController(rootViewController: assembly.makeModule())

        self.present(module: controller)
    }
}

// MARK: - CourseInfoTabReviewsViewController: CourseInfoTabReviewsViewDelegate -

extension CourseInfoTabReviewsViewController: CourseInfoTabReviewsViewDelegate {
    func courseInfoTabReviewsViewDidPaginationRequesting(_ courseInfoTabReviewsView: CourseInfoTabReviewsView) {
        guard self.canTriggerPagination else {
            return
        }

        self.canTriggerPagination = false
        self.interactor.doNextCourseReviewsFetch(request: .init())
    }

    func courseInfoTabReviewsViewDidRequestWriteReview(_ courseInfoTabReviewsView: CourseInfoTabReviewsView) {
        self.interactor.doWriteCourseReviewPresentation(request: .init())
    }

    func courseInfoTabReviewsViewDidRequestEditReview(_ courseInfoTabReviewsView: CourseInfoTabReviewsView) {
        self.interactor.doWriteCourseReviewPresentation(request: .init())
    }
}
