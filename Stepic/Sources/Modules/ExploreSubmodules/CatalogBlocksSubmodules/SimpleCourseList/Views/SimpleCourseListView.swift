import UIKit

protocol SimpleCourseListViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func updateCollectionViewData(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource)
}
