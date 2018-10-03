//
//  CourseListsCollectionPresenter.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 03.09.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

protocol CourseListsCollectionPresenterProtocol: class {
    func presentCourses(response: CourseListsCollection.ShowCourseLists.Response)
}

final class CourseListsCollectionPresenter: CourseListsCollectionPresenterProtocol {
    weak var viewController: CourseListsCollectionViewControllerProtocol?

    func presentCourses(response: CourseListsCollection.ShowCourseLists.Response) {
        var viewModel: CourseListsCollection.ShowCourseLists.ViewModel

        switch response.result {
        case .failure(let error):
            viewModel = CourseListsCollection.ShowCourseLists.ViewModel(state: .emptyResult)
        case .success(let result):
            let courses = result.map { courseList in
                CourseListsCollectionViewModel(
                    title: courseList.title,
                    description: self.makeCourseListDescription(courseList: courseList),
                    summary: courseList.listDescription,
                    courseList: CollectionCourseListType(ids: courseList.coursesArray)
                )
            }
            if courses.isEmpty {
                viewModel = CourseListsCollection.ShowCourseLists.ViewModel(state: .emptyResult)
            } else {
                viewModel = CourseListsCollection.ShowCourseLists.ViewModel(state: .result(data: courses))
            }
        }

        self.viewController?.displayCourseLists(viewModel: viewModel)
    }

    private func makeCourseListDescription(courseList: CourseListModel) -> String {
        let pluralizedCountString = StringHelper.pluralize(
            number: courseList.coursesArray.count,
            forms: [
                NSLocalizedString("courses1", comment: ""),
                NSLocalizedString("courses234", comment: ""),
                NSLocalizedString("courses567890", comment: "")
            ]
        )
        return "\(courseList.coursesArray.count) \(pluralizedCountString)"
    }
}
