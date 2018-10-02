//
//  CourseListPresenter.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 22.08.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

class CourseListAssembly: Assembly {
    let type: CourseListType
    let colorMode: CourseListColorMode

    // Input
    var moduleInput: CourseListInputProtocol?

    // Output
    private weak var moduleOutput: CourseListOutputProtocol?

    fileprivate func makeViewController(
        interactor: CourseListInteractorProtocol
    ) -> (UIViewController & CourseListViewControllerProtocol) {
        fatalError("Property should be overridden in subclass")
    }

    fileprivate init(
        type: CourseListType,
        colorMode: CourseListColorMode,
        output: CourseListOutputProtocol? = nil
    ) {
        self.type = type
        self.colorMode = colorMode
        self.moduleOutput = output
    }

    func makeModule() -> UIViewController {
        let servicesFactory = CourseListServicesFactory(
            type: self.type,
            coursesAPI: CoursesAPI(),
            userCoursesAPI: UserCoursesAPI(),
            searchResultsAPI: SearchResultsAPI()
        )

        let presenter = CourseListPresenter()
        let provider = CourseListProvider(
            type: self.type,
            networkService: servicesFactory.makeNetworkService(),
            persistenceService: servicesFactory.makePersistenceService(),
            progressesNetworkService: ProgressesNetworkService(
                progressesAPI: ProgressesAPI()
            ),
            reviewSummariesNetworkService: CourseReviewSummariesNetworkService(
                courseReviewSummariesAPI: CourseReviewSummariesAPI()
            )
        )

        let interactor = CourseListInteractor(
            presenter: presenter,
            provider: provider,
            adaptiveStorageManager: AdaptiveStorageManager(),
            courseSubscriber: CourseSubscriber()
        )
        self.moduleInput = interactor

        let controller = self.makeViewController(interactor: interactor)
        presenter.viewController = controller
        interactor.moduleOutput = self.moduleOutput
        return controller
    }
}

final class HorizontalCourseListAssembly: CourseListAssembly {
    static let defaultMaxNumberOfDisplayedCourses = 14

    private let maxNumberOfDisplayedCourses: Int?

    fileprivate override func makeViewController(
        interactor: CourseListInteractorProtocol
    ) -> (UIViewController & CourseListViewControllerProtocol) {
        return HorizontalCourseListViewController(
            interactor: interactor,
            colorMode: self.colorMode,
            maxNumberOfDisplayedCourses: self.maxNumberOfDisplayedCourses
        )
    }

    init(
        type: CourseListType,
        colorMode: CourseListColorMode,
        maxNumberOfDisplayedCourses: Int? = HorizontalCourseListAssembly.defaultMaxNumberOfDisplayedCourses,
        output: CourseListOutputProtocol? = nil
    ) {
        self.maxNumberOfDisplayedCourses = maxNumberOfDisplayedCourses
        super.init(
            type: type,
            colorMode: colorMode,
            output: output
        )
    }
}

final class VerticalCourseListAssembly: CourseListAssembly {
    private let presentationDescription: VerticalCourseListViewController.PresentationDescription?

    fileprivate override func makeViewController(
        interactor: CourseListInteractorProtocol
    ) -> (UIViewController & CourseListViewControllerProtocol) {
        return VerticalCourseListViewController(
            interactor: interactor,
            colorMode: self.colorMode,
            presentationDescription: self.presentationDescription
        )
    }

    init(
        type: CourseListType,
        colorMode: CourseListColorMode,
        presentationDescription: VerticalCourseListViewController.PresentationDescription?,
        output: CourseListOutputProtocol? = nil
    ) {
        self.presentationDescription = presentationDescription
        super.init(
            type: type,
            colorMode: colorMode,
            output: output
        )
    }
}
