import SnapKit
import UIKit

protocol UserCoursesReviewsViewDelegate: AnyObject {
    func userCoursesReviewsViewRefreshControlDidRefresh(_ view: UserCoursesReviewsView)
}

extension UserCoursesReviewsView {
    struct Appearance {
        let estimatedRowHeight: CGFloat = 158
    }
}

final class UserCoursesReviewsView: UIView {
    let appearance: Appearance

    weak var delegate: UserCoursesReviewsViewDelegate?

    private lazy var refreshControl = UIRefreshControl()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = self.appearance.estimatedRowHeight
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        tableView.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlDidChangeValue), for: .valueChanged)

        tableView.register(cellClass: UserCoursesReviewsPossibleReviewTableViewCell.self)
        tableView.register(cellClass: UserCoursesReviewsLeavedReviewTableViewCell.self)

        return tableView
    }()

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public API

    func updateTableViewData(delegate: UITableViewDelegate & UITableViewDataSource) {
        self.refreshControl.endRefreshing()

        self.tableView.delegate = delegate
        self.tableView.dataSource = delegate
        self.tableView.reloadData()
    }

    func showLoading() {
        self.tableView.skeleton.viewBuilder = { SubmissionsSkeletonView() }
        self.tableView.skeleton.show()
    }

    func hideLoading() {
        self.tableView.skeleton.hide()
    }

    // MARK: Private API

    @objc
    private func refreshControlDidChangeValue() {
        self.delegate?.userCoursesReviewsViewRefreshControlDidRefresh(self)
    }
}

extension UserCoursesReviewsView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.tableView)
    }

    func makeConstraints() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
