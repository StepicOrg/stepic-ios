import SnapKit
import UIKit

extension CourseListView {
    struct Appearance {
        let layoutMinimumLineSpacing: CGFloat = 16.0
        let layoutMinimumInteritemSpacing: CGFloat = 16.0
        let layoutItemHeight: CGFloat = 140.0

        let lightModeBackgroundColor = UIColor.stepikBackground
        let darkModeBackgroundColor = UIColor.stepikAccentFixed
        let darkModeDarkInterfaceStyleBackgroundColor = UIColor.stepikSecondaryBackground

        let horizontalLayoutNextPageWidth: CGFloat = 12.0
    }
}

class CourseListView: UIView {
    let appearance: Appearance
    let colorMode: CourseListColorMode

    // swiftlint:disable:next implicitly_unwrapped_optional
    fileprivate var collectionView: UICollectionView!
    fileprivate weak var delegate: CourseListViewDelegate?

    var flowLayout: UICollectionViewFlowLayout {
        fatalError("Use subclass of CourseListView with concrete layout")
    }

    override var intrinsicContentSize: CGSize {
        self.collectionView.collectionViewLayout.collectionViewContentSize
    }

    init(
        frame: CGRect = .zero,
        colorMode: CourseListColorMode = .default,
        viewDelegate: CourseListViewDelegate,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        self.colorMode = colorMode

        self.delegate = viewDelegate

        super.init(frame: frame)

        self.collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: self.flowLayout
        )

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    // swiftlint:disable:next unavailable_function
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateItemSize(self.calculateItemSize())
        self.invalidateIntrinsicContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.performBlockIfAppearanceChanged(from: previousTraitCollection) {
            self.updateViewColor()
        }
    }

    // swiftlint:disable:next unavailable_function
    func calculateItemSize() -> CGSize {
        fatalError("Use subclass of CourseListView with concrete layout")
    }

    func updateItemSize(_ itemSize: CGSize) {
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize != itemSize {
            layout.itemSize = itemSize
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    func updateCollectionViewData(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource) {
        self.collectionView.delegate = delegate
        self.collectionView.dataSource = dataSource
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    private func updateViewColor() {
        self.backgroundColor = self.getBackgroundColor(for: self.colorMode)
    }

    // MARK: - ColorMode

    private func getBackgroundColor(for colorMode: CourseListColorMode) -> UIColor {
        switch colorMode {
        case .light:
            return self.appearance.lightModeBackgroundColor
        case .dark:
            if #available(iOS 13.0, *), self.traitCollection.userInterfaceStyle == .dark {
                return self.appearance.darkModeDarkInterfaceStyleBackgroundColor
            } else {
                return self.appearance.darkModeBackgroundColor
            }
        }
    }

    // MARK: - Loading state

    func showLoading() {
        self.collectionView.skeleton.viewBuilder = {
            CourseWidgetSkeletonView()
        }
        self.collectionView.skeleton.show()
    }

    func hideLoading() {
        self.collectionView.skeleton.hide()
    }
}

extension CourseListView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.updateViewColor()
        self.setupCollectionView()
    }

    func addSubviews() {
        self.addSubview(self.collectionView)
    }

    func makeConstraints() {
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupCollectionView() {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false

        switch self.colorMode {
        case .light:
            self.collectionView.register(
                LightCourseListCollectionViewCell.self,
                forCellWithReuseIdentifier: LightCourseListCollectionViewCell.defaultReuseIdentifier
            )
        case .dark:
            self.collectionView.register(
                DarkCourseListCollectionViewCell.self,
                forCellWithReuseIdentifier: DarkCourseListCollectionViewCell.defaultReuseIdentifier
            )
        }

        self.collectionView.register(
            viewClass: CollectionViewReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter
        )
        self.collectionView.register(
            viewClass: CollectionViewReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader
        )

        self.collectionView.isPagingEnabled = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.contentInset = .zero
        self.collectionView.backgroundColor = .clear
    }
}

// Subclasses for two orientations

final class VerticalCourseListView: CourseListView,
                                    UICollectionViewDelegate,
                                    UICollectionViewDataSource {
    private let columnsCount: Int
    // We should use proxy cause we are using willDisplay method in delegate for pagination
    // and some methods to show footer/header in data source
    // swiftlint:disable weak_delegate
    private var storedCollectionViewDelegate: UICollectionViewDelegate
    private var storedCollectionViewDataSource: UICollectionViewDataSource
    // swiftlint:enable weak_delegate

    private lazy var verticalCourseFlowLayout: VerticalCourseListFlowLayout = {
        let layout = VerticalCourseListFlowLayout(
            columnsCount: self.columnsCount,
            isHeaderHidden: self.isHeaderViewHidden
        )
        layout.minimumInteritemSpacing = self.appearance.layoutMinimumInteritemSpacing
        layout.minimumLineSpacing = self.appearance.layoutMinimumLineSpacing
        return layout
    }()

    override var flowLayout: UICollectionViewFlowLayout {
        self.verticalCourseFlowLayout
    }

    private let isHeaderViewHidden: Bool
    var isPaginationViewHidden = true {
        didSet {
            self.updatePagination()
        }
    }

    var headerView: UIView?
    var paginationView: UIView?

    init(
        frame: CGRect,
        columnsCount: Int,
        colorMode: CourseListColorMode,
        delegate: UICollectionViewDelegate,
        dataSource: UICollectionViewDataSource,
        viewDelegate: CourseListViewDelegate,
        isHeaderViewHidden: Bool,
        appearance: Appearance = CourseListView.Appearance()
    ) {
        self.columnsCount = columnsCount
        self.storedCollectionViewDelegate = delegate
        self.storedCollectionViewDataSource = dataSource
        self.isHeaderViewHidden = isHeaderViewHidden
        super.init(
            frame: frame,
            colorMode: colorMode,
            viewDelegate: viewDelegate,
            appearance: appearance
        )
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateCollectionViewData(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource) {
        self.storedCollectionViewDelegate = delegate
        self.storedCollectionViewDataSource = dataSource
        super.updateCollectionViewData(delegate: self, dataSource: self)
    }

    override func calculateItemSize() -> CGSize {
        let width = self.bounds.width - self.appearance.layoutMinimumInteritemSpacing * CGFloat(self.columnsCount + 1)
        return CGSize(width: width / CGFloat(self.columnsCount), height: self.appearance.layoutItemHeight)
    }

    private func updatePagination() {
        self.collectionView.performBatchUpdates(
            _: { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.verticalCourseFlowLayout.isPaginationHidden = strongSelf.isPaginationViewHidden
            }
        )
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.storedCollectionViewDelegate.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        self.storedCollectionViewDelegate.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)

        // Pagination working only when collection has one section
        guard indexPath.section == 0 else {
            return
        }

        // Handle pagination
        let itemsCount = collectionView.numberOfItems(inSection: indexPath.section)
        if indexPath.row + 1 == itemsCount {
            self.delegate?.courseListViewDidPaginationRequesting(self)
        }
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.storedCollectionViewDataSource.collectionView(
            collectionView,
            numberOfItemsInSection: section
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        self.storedCollectionViewDataSource.collectionView(
            collectionView,
            cellForItemAt: indexPath
        )
    }

    // Crash if present here
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let view: CollectionViewReusableView = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionFooter,
                    for: indexPath
                )
            if let footerView = self.paginationView {
                view.attachView(footerView)
            }
            return view
        } else if kind == UICollectionView.elementKindSectionHeader {
            let view: CollectionViewReusableView = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    for: indexPath
                )
            if let headerView = self.headerView {
                view.attachView(headerView)
            }
            return view
        }

        fatalError("Kind is not supported")
    }
}

final class HorizontalCourseListView: CourseListView {
    private let columnsCount: Int
    private let rowsCount: Int

    private lazy var horizontalCourseFlowLayout: HorizontalCourseListFlowLayout = {
        let layout = HorizontalCourseListFlowLayout(
            rowsCount: self.rowsCount,
            columnsCount: self.columnsCount
        )
        layout.minimumInteritemSpacing = self.appearance.layoutMinimumInteritemSpacing
        layout.minimumLineSpacing = self.appearance.layoutMinimumLineSpacing
        return layout
    }()

    override var flowLayout: UICollectionViewFlowLayout {
        self.horizontalCourseFlowLayout
    }

    init(
        frame: CGRect,
        columnsCount: Int,
        rowsCount: Int,
        colorMode: CourseListColorMode,
        delegate: UICollectionViewDelegate,
        dataSource: UICollectionViewDataSource,
        viewDelegate: CourseListViewDelegate,
        appearance: Appearance = CourseListView.Appearance()
    ) {
        self.columnsCount = columnsCount
        self.rowsCount = rowsCount
        super.init(
            frame: frame,
            colorMode: colorMode,
            viewDelegate: viewDelegate,
            appearance: appearance
        )
        self.collectionView.delegate = delegate
        self.collectionView.dataSource = dataSource

        // Make scroll faster
        self.collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func calculateItemSize() -> CGSize {
        let width = self.bounds.width
            - self.appearance.layoutMinimumInteritemSpacing * CGFloat(self.columnsCount + 1)
            - self.appearance.horizontalLayoutNextPageWidth
        return CGSize(
            width: width / CGFloat(self.columnsCount),
            height: self.appearance.layoutItemHeight
        )
    }
}

// Wrapper for reusable views

final class CollectionViewReusableView: UICollectionReusableView, Reusable {
    private var subview: UIView?

    func attachView(_ view: UIView) {
        self.clipsToBounds = true
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.subview = view
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.subview?.removeFromSuperview()
    }
}

// Cause we can't init cell with custom initializer let's use custom classes

private class LightCourseListCollectionViewCell: CourseListCollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame, colorMode: .light)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var defaultReuseIdentifier: String {
        String(describing: CourseListCollectionViewCell.self)
    }
}

private class DarkCourseListCollectionViewCell: CourseListCollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame, colorMode: .dark)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static var defaultReuseIdentifier: String {
        String(describing: CourseListCollectionViewCell.self)
    }
}
