import UIKit

final class CourseListCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    weak var delegate: CourseListViewControllerDelegate?

    private var maxNumberOfDisplayedCourses: Int?
    var viewModels: [CourseWidgetViewModel]

    init(
        viewModels: [CourseWidgetViewModel] = [],
        maxNumberOfDisplayedCourses: Int? = nil
    ) {
        self.viewModels = viewModels
        self.maxNumberOfDisplayedCourses = maxNumberOfDisplayedCourses
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if let maxNumberOfDisplayedCourses = self.maxNumberOfDisplayedCourses {
            return min(maxNumberOfDisplayedCourses, self.viewModels.count)
        }
        return self.viewModels.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: CourseListCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.configure(viewModel: self.viewModels[indexPath.row])
        cell.delegate = self

        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale

        return cell
    }
}

extension CourseListCollectionViewDataSource: CourseListCollectionViewCellDelegate {
    func widgetPrimaryButtonClicked(viewModel: CourseWidgetViewModel?) {
        guard let viewModel = viewModel else {
            return
        }

        self.delegate?.primaryButtonClicked(viewModel: viewModel)
    }
}
