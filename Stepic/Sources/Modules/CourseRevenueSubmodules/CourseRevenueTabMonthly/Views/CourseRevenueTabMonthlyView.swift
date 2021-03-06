import SnapKit
import UIKit

protocol CourseRevenueTabMonthlyViewDelegate: AnyObject {
    func courseRevenueTabMonthlyViewDidPaginationRequesting(_ view: CourseRevenueTabMonthlyView)
    func courseRevenueTabMonthlyViewDidClickErrorPlaceholderViewButton(_ view: CourseRevenueTabMonthlyView)
}

extension CourseRevenueTabMonthlyView {
    struct Appearance {
        let paginationViewHeight: CGFloat = 52

        let backgroundColor = UIColor.stepikBackground
    }
}

final class CourseRevenueTabMonthlyView: UIView {
    let appearance: Appearance

    weak var delegate: CourseRevenueTabMonthlyViewDelegate?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 292
        tableView.separatorStyle = .none

        tableView.delegate = self
        tableView.register(cellClass: CourseRevenueTabMonthlyTableViewCell.self)

        return tableView
    }()

    private lazy var placeholderView: StepikPlaceholderView = {
        let appearance = StepikPlaceholderView.Appearance(backgroundColor: self.appearance.backgroundColor)
        let view = StepikPlaceholderView()
        view.appearance = appearance
        view.delegate = self
        view.isHidden = true
        return view
    }()

    private var placeholderViewTopConstraint: Constraint?

    // Proxify delegates
    private weak var pageScrollViewDelegate: UIScrollViewDelegate?

    private var shouldShowPaginationView = false
    var paginationView: UIView?

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

    func updateTableViewData(dataSource: UITableViewDataSource) {
        self.tableView.dataSource = dataSource
        self.tableView.reloadData()
    }

    func setLoading(_ isLoading: Bool) {
        self.tableView.skeleton.hide()

        if isLoading {
            DispatchQueue.main.async {
                self.tableView.skeleton.viewBuilder = { CourseRevenueTabMonthlyCellSkeletonView() }
                self.tableView.skeleton.show()
            }
        }
    }

    func setPaginationViewVisible(_ isVisible: Bool) {
        if isVisible {
            self.shouldShowPaginationView = true
            self.tableView.tableFooterView = self.paginationView
            self.tableView.tableFooterView?.frame = CGRect(
                x: 0,
                y: 0,
                width: self.frame.width,
                height: self.appearance.paginationViewHeight
            )
        } else {
            self.shouldShowPaginationView = false
            self.tableView.tableFooterView?.frame = .zero
            self.tableView.tableFooterView = nil
        }
    }

    func setErrorPlaceholderVisible(_ isVisible: Bool) {
        if isVisible {
            self.placeholderView.set(placeholder: .noConnectionCourseBenefits)
            self.placeholderView.delegate = self
            self.placeholderView.isHidden = false
        } else {
            self.placeholderView.isHidden = true
        }
    }

    func setEmptyPlaceholderVisible(_ isVisible: Bool) {
        if isVisible {
            self.placeholderView.set(placeholder: .emptyCourseBenefits)
            self.placeholderView.delegate = nil
            self.placeholderView.isHidden = false
        } else {
            self.placeholderView.isHidden = true
        }
    }
}

extension CourseRevenueTabMonthlyView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.tableView)
        self.addSubview(self.placeholderView)
    }

    func makeConstraints() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.placeholderView.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderView.snp.makeConstraints { make in
            self.placeholderViewTopConstraint = make.top.equalToSuperview().constraint
            make.centerX.leading.bottom.trailing.equalToSuperview()
        }
    }
}

extension CourseRevenueTabMonthlyView: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1,
           tableView.numberOfSections == 1,
           self.shouldShowPaginationView {
            self.delegate?.courseRevenueTabMonthlyViewDidPaginationRequesting(self)
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { nil }
}

extension CourseRevenueTabMonthlyView: ScrollablePageViewProtocol {
    var scrollViewDelegate: UIScrollViewDelegate? {
        get {
            self.pageScrollViewDelegate
        }
        set {
            self.pageScrollViewDelegate = newValue
        }
    }

    var contentInsets: UIEdgeInsets {
        get {
            self.tableView.contentInset
        }
        set {
            self.tableView.contentInset = newValue
            self.placeholderViewTopConstraint?.update(offset: newValue.top)

            // Manually update contentOffset if needed APPS-3384
            let newContentOffset = CGPoint(x: 0, y: -newValue.top)
            if self.contentOffset != newContentOffset {
                self.contentOffset = newContentOffset
            }
        }
    }

    var contentOffset: CGPoint {
        get {
            self.tableView.contentOffset
        }
        set {
            self.tableView.contentOffset = newValue
        }
    }

    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
            self.tableView.contentInsetAdjustmentBehavior
        }
        set {
            self.tableView.contentInsetAdjustmentBehavior = newValue
        }
    }
}

extension CourseRevenueTabMonthlyView: StepikPlaceholderViewDelegate {
    func buttonDidClick(_ button: UIButton) {
        self.delegate?.courseRevenueTabMonthlyViewDidClickErrorPlaceholderViewButton(self)
    }
}
