//
//  ExploreExplorePresenter.swift
//  stepik-ios
//
//  Created by Stepik on 10/09/2018.
//  Copyright 2018 Stepik. All rights reserved.
//

import UIKit

protocol ExplorePresenterProtocol {
    func presentContent(response: Explore.LoadContent.Response)
    func presentLanguageSwitchBlock(response: Explore.CheckLanguageSwitchAvailability.Response)
    func presentFullscreenCourseList(response: Explore.PresentFullscreenCourseListModule.Response)

    func presentCourseInfo(response: Explore.PresentCourseInfo.Response)
    func presentCourseSyllabus(response: Explore.PresentCourseSyllabus.Response)
    func presentLastStep()
}

final class ExplorePresenter: ExplorePresenterProtocol {
    weak var viewController: ExploreViewControllerProtocol?

    func presentContent(response: Explore.LoadContent.Response) {
        self.viewController?.displayContent(
            viewModel: .init(state: .normal(contentLanguage: response.contentLanguage))
        )
    }

    func presentLanguageSwitchBlock(response: Explore.CheckLanguageSwitchAvailability.Response) {
        self.viewController?.displayLanguageSwitchBlock(
            viewModel: .init(isHidden: response.isHidden)
        )
    }

    func presentFullscreenCourseList(response: Explore.PresentFullscreenCourseListModule.Response) {
        self.viewController?.displayFullscreenCourseList(
            viewModel: .init(courseListType: response.courseListType)
        )
    }

    func presentCourseInfo(response: Explore.PresentCourseInfo.Response) {
        self.viewController?.displayCourseInfo(response: .init(course: response.course))
    }

    func presentCourseSyllabus(response: Explore.PresentCourseSyllabus.Response) {
        self.viewController?.displayCourseSyllabus(response: .init(course: response.course))
    }

    func presentLastStep() {
    }
}
