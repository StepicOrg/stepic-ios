import UIKit

final class CourseListContainerViewFactory {
    struct HorizontalHeaderDescription {
        var title: String?
        var summary: String?
        var shouldShowAllButton: Bool

        init(
            title: String?,
            summary: String?,
            shouldShowAllButton: Bool = true
        ) {
            self.title = title
            self.summary = summary
            self.shouldShowAllButton = shouldShowAllButton
        }
    }

    struct HorizontalCoursesCollectionHeaderDescription {
        var title: String?
        var summary: String?
        var description: String
        var color: GradientCoursesPlaceholderView.Color
    }

    enum Appearance {
        static let horizontalContentInsets = UIEdgeInsets(top: 0, left: -1, bottom: 16, right: -1)
        static let horizontalCoursesCollectionContentInsets = UIEdgeInsets(
            top: 0,
            left: -1,
            bottom: 8, // cause have top spacing in next
            right: -1
        )
    }

    let colorMode: CourseListColorMode

    init(colorMode: CourseListColorMode = .default) {
        self.colorMode = colorMode
    }

    func makeHorizontalContainerView(
        for contentView: UIView,
        headerDescription: HorizontalHeaderDescription
    ) -> ExploreBlockContainerView {
        let headerView = ExploreBlockHeaderView(
            appearance: self.colorMode.exploreBlockHeaderViewAppearance
        )
        headerView.shouldShowAllButton = headerDescription.shouldShowAllButton
        headerView.titleText = headerDescription.title
        headerView.summaryText = headerDescription.summary

        return self.makeHorizontalContainerView(headerView: headerView, contentView: contentView)
    }

    func makeHorizontalCoursesCollectionContainerView(
        for contentView: UIView,
        headerDescription: HorizontalCoursesCollectionHeaderDescription
    ) -> ExploreBlockContainerView {
        let headerView = ExploreCoursesCollectionHeaderView(
            description: headerDescription.description,
            color: headerDescription.color
        )
        headerView.titleText = headerDescription.title
        headerView.summaryText = headerDescription.summary

        return self.makeHorizontalContainerView(headerView: headerView, contentView: contentView)
    }

    private func makeHorizontalContainerView(
        headerView: UIView & ExploreBlockHeaderViewProtocol,
        contentView: UIView
    ) -> ExploreBlockContainerView {
        var appearance = self.colorMode.exploreBlockContainerViewAppearance
        appearance.contentViewInsets.top = Appearance.horizontalContentInsets.top
        appearance.contentViewInsets.bottom = Appearance.horizontalContentInsets.bottom

        return ExploreBlockContainerView(
            headerView: headerView,
            contentView: contentView,
            shouldShowSeparator: false,
            appearance: appearance
        )
    }
}
