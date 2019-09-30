import SnapKit
import UIKit

protocol CourseInfoTabReviewsViewDelegate: class {
    func courseInfoTabReviewsViewDidPaginationRequesting(_ courseInfoTabReviewsView: CourseInfoTabReviewsView)
    func courseInfoTabReviewsViewDidRequestWriteReview(_ courseInfoTabReviewsView: CourseInfoTabReviewsView)
}

extension CourseInfoTabReviewsView {
    struct Appearance {
        let paginationViewHeight: CGFloat = 52

        let emptyStateLabelFont = UIFont.systemFont(ofSize: 17, weight: .light)
        let emptyStateLabelColor = UIColor(hex: 0x535366, alpha: 0.4)
        let emptyStateLabelInsets = UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 35)
    }
}

final class CourseInfoTabReviewsView: UIView {
    let appearance: Appearance
    weak var delegate: CourseInfoTabReviewsViewDelegate?

    private lazy var writeReviewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("WriteCourseReviewActionCreate", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(self.writeReviewDidClick), for: .touchUpInside)
        button.setTitleColor(.mainDark, for: .normal)
        return button
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100.0
        tableView.separatorStyle = .none
        tableView.allowsSelection = false

        tableView.delegate = self
        tableView.register(cellClass: CourseInfoTabReviewsTableViewCell.self)

        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("NoReviews", comment: "")
        label.numberOfLines = 0
        label.textColor = self.appearance.emptyStateLabelColor
        label.font = self.appearance.emptyStateLabelFont
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // Proxify delegates
    private weak var pageScrollViewDelegate: UIScrollViewDelegate?

    private var shouldShowPaginationView = false
    var paginationView: UIView?

    var canWriteReview: Bool = false {
        didSet {
            if self.canWriteReview {
                self.tableView.tableHeaderView = self.writeReviewButton
                self.tableView.tableHeaderView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: self.frame.width,
                    height: 52
                )
            } else {
                self.tableView.tableHeaderView?.frame = .zero
                self.tableView.tableHeaderView = nil
            }
        }
    }

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTableViewData(dataSource: UITableViewDataSource) {
        let numberOfRows = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
        self.tableView.isHidden = numberOfRows == 0
        self.emptyStateLabel.isHidden = numberOfRows != 0

        self.tableView.dataSource = dataSource
        self.tableView.reloadData()
    }

    func showPaginationView() {
        self.shouldShowPaginationView = true
        self.tableView.tableFooterView = self.paginationView
        self.tableView.tableFooterView?.frame = CGRect(
            x: 0,
            y: 0,
            width: self.frame.width,
            height: self.appearance.paginationViewHeight
        )
    }

    func hidePaginationView() {
        self.shouldShowPaginationView = false
        self.tableView.tableFooterView?.frame = .zero
        self.tableView.tableFooterView = nil
    }

    func showLoading() {
        self.tableView.skeleton.viewBuilder = {
            CourseInfoTabReviewsSkeletonView()
        }
        self.tableView.skeleton.show()
    }

    func hideLoading() {
        self.tableView.skeleton.hide()
    }

    @objc
    private func writeReviewDidClick() {
        self.delegate?.courseInfoTabReviewsViewDidRequestWriteReview(self)
    }
}

extension CourseInfoTabReviewsView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.tableView)
        self.addSubview(self.emptyStateLabel)
    }

    func makeConstraints() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.emptyStateLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading
                .greaterThanOrEqualToSuperview()
                .offset(self.appearance.emptyStateLabelInsets.left)
                .priority(999)
            make.trailing
                .lessThanOrEqualToSuperview()
                .offset(-self.appearance.emptyStateLabelInsets.right)
                .priority(999)
            make.width.lessThanOrEqualTo(600)
        }
    }
}

extension CourseInfoTabReviewsView: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1,
           tableView.numberOfSections == 1,
           self.shouldShowPaginationView {
            self.delegate?.courseInfoTabReviewsViewDidPaginationRequesting(self)
        }
    }
}

extension CourseInfoTabReviewsView: CourseInfoScrollablePageViewProtocol {
    var scrollViewDelegate: UIScrollViewDelegate? {
        get {
            return self.pageScrollViewDelegate
        }
        set {
            self.pageScrollViewDelegate = newValue
        }
    }

    var contentInsets: UIEdgeInsets {
        get {
            return self.tableView.contentInset
        }
        set {
            self.emptyStateLabel.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(newValue.top / 2)
            }
            self.tableView.contentInset = newValue
        }
    }

    var contentOffset: CGPoint {
        get {
            return self.tableView.contentOffset
        }
        set {
            self.tableView.contentOffset = newValue
        }
    }

    @available(iOS 11.0, *)
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
            return self.tableView.contentInsetAdjustmentBehavior
        }
        set {
            self.tableView.contentInsetAdjustmentBehavior = newValue
        }
    }
}
