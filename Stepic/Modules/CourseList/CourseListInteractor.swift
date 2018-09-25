//
//  CourseListInteractor.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 22.08.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

protocol CourseListInteractorProtocol: class {
    func fetchCourses(request: CourseList.ShowCourses.Request)
    func fetchNextCourses(request: CourseList.LoadNextCourses.Request)

    func doPrimaryAction(request: CourseList.PrimaryCourseAction.Request)
    func doSecondaryAction(request: CourseList.SecondaryCourseAction.Request)
    func doMainAction(request: CourseList.MainCourseAction.Request)
}

final class CourseListInteractor: CourseListInteractorProtocol {
    typealias PaginationState = (page: Int, hasNext: Bool)

    weak var moduleOutput: CourseListOutputProtocol?

    let presenter: CourseListPresenterProtocol
    let provider: CourseListProviderProtocol
    let adaptiveStorageManager: AdaptiveStorageManagerProtocol
    let courseSubscriber: CourseSubscriberProtocol

    private var isOnline: Bool = false
    private var paginationState = PaginationState(page: 1, hasNext: true)
    private var currentCourses: [Course] = []

    init(
        presenter: CourseListPresenterProtocol,
        provider: CourseListProviderProtocol,
        adaptiveStorageManager: AdaptiveStorageManagerProtocol,
        courseSubscriber: CourseSubscriberProtocol
    ) {
        self.presenter = presenter
        self.provider = provider
        self.adaptiveStorageManager = adaptiveStorageManager
        self.courseSubscriber = courseSubscriber
    }

    // MARK: - Public methods

    func fetchCourses(request: CourseList.ShowCourses.Request) {
        // Check for state and if state == offline, just fetch cached courses
        // if state == online, fetch from network and show
        firstly {
            self.isOnline
                ? self.provider.fetchRemote(page: 1)
                : self.provider.fetchCached()
        }.done { courses, meta in
            self.paginationState = PaginationState(
                page: meta.page,
                hasNext: meta.hasNext
            )

            self.currentCourses = courses
            let courses = CourseList.AvailableCourses(
                fetchedCourses: CourseList.ListData(courses: courses, hasNextPage: meta.hasNext),
                availableAdaptiveCourses: self.getAvailableAdaptiveCourses(from: courses)
            )
            let response = CourseList.ShowCourses.Response(result: Result.success(courses))
            self.presenter.presentCourses(response: response)
        }.catch { _ in
            let result = Result<CourseList.AvailableCourses>.failure(Error.fetchFailed)
            let response = CourseList.ShowCourses.Response(result: result)
            self.presenter.presentCourses(response: response)
        }
    }

    func fetchNextCourses(request: CourseList.LoadNextCourses.Request) {
        // If we are
        // - in offline mode
        // - have no more courses
        // then ignore request and pass empty list to presenter
        if !self.isOnline || !self.paginationState.hasNext {
            let result = Result.success(
                CourseList.AvailableCourses(
                    fetchedCourses: CourseList.ListData(courses: [], hasNextPage: false),
                    availableAdaptiveCourses: Set<Course>()
                )
            )
            let response = CourseList.LoadNextCourses.Response(result: result)
            self.presenter.presentNextCourses(response: response)
            return
        }

        let nextPageNumber = self.paginationState.page + 1
        self.provider.fetchRemote(page: nextPageNumber).done { courses, meta in
            self.paginationState = PaginationState(
                page: meta.page,
                hasNext: meta.hasNext
            )

            self.currentCourses.append(contentsOf: courses)
            let courses = CourseList.AvailableCourses(
                fetchedCourses: CourseList.ListData(courses: courses, hasNextPage: meta.hasNext),
                availableAdaptiveCourses: self.getAvailableAdaptiveCourses(from: courses)
            )
            let response = CourseList.LoadNextCourses.Response(result: Result.success(courses))
            self.presenter.presentNextCourses(response: response)
        }.catch { _ in
            let result = Result<CourseList.AvailableCourses>.failure(Error.fetchFailed)
            let response = CourseList.LoadNextCourses.Response(result: result)
            self.presenter.presentNextCourses(response: response)
        }
    }

    func doPrimaryAction(request: CourseList.PrimaryCourseAction.Request) {
        self.presenter.presentWaitingState()

        guard let targetIndex = Int(request.viewModelUniqueIdentifier),
              let targetCourse = self.currentCourses[safe: targetIndex] else {
            fatalError("Invalid module state")
        }

        if targetCourse.enrolled {
            // Enrolled course -> open last step
            self.moduleOutput?.presentLastStep()
            self.presenter.dismissWaitingState()
        } else {
            // Unenrolled course -> join, open last step
            self.courseSubscriber.join(course: targetCourse, source: .widget).done { course in
                self.currentCourses[targetIndex] = course
                self.moduleOutput?.presentLastStep()
                self.presenter.dismissWaitingState()
            }.catch { _ in

            }
        }
    }

    func doSecondaryAction(request: CourseList.SecondaryCourseAction.Request) {
        self.presenter.presentWaitingState()

        guard let targetIndex = Int(request.viewModelUniqueIdentifier),
              let targetCourse = self.currentCourses[safe: targetIndex] else {
            fatalError("Invalid module state")
        }

        defer {
            self.presenter.dismissWaitingState()
        }

        if targetCourse.enrolled {
            // Enrolled course
            // - adaptive -> info
            // - normal -> syllabus
            if self.adaptiveStorageManager.canOpenInAdaptiveMode(courseId: targetCourse.id) {
                self.moduleOutput?.presentCourseInfo(course: targetCourse)
            } else {
                self.moduleOutput?.presentCourseSyllabus(course: targetCourse)
            }
        } else {
            // Unenrolled course
            // - adaptive -> info
            // - normal -> info
            self.moduleOutput?.presentCourseInfo(course: targetCourse)
        }
    }

    func doMainAction(request: CourseList.MainCourseAction.Request) {
        self.presenter.presentWaitingState()

        guard let targetIndex = Int(request.viewModelUniqueIdentifier),
              let targetCourse = self.currentCourses[safe: targetIndex] else {
            fatalError("Invalid module state")
        }

        defer {
            self.presenter.dismissWaitingState()
        }

        if targetCourse.enrolled {
            // Enrolled course -> open last step
            self.moduleOutput?.presentLastStep()
        } else {
            // Unenrolled course -> info
            self.moduleOutput?.presentCourseInfo(course: targetCourse)
        }
    }

    // MARK: - Private methods

    private func getAvailableAdaptiveCourses(from courses: [Course]) -> Set<Course> {
        let availableInAdaptiveMode = courses
            .filter { self.adaptiveStorageManager.canOpenInAdaptiveMode(courseId: $0.id) }
        return Set<Course>(availableInAdaptiveMode)
    }

    // MARK: - Enums

    enum Error: Swift.Error {
        case fetchFailed
    }
}

extension CourseListInteractor: CourseListInputProtocol {
    func reload() {
        self.isOnline = true

        let fakeRequest = CourseList.ShowCourses.Request()
        self.fetchCourses(request: fakeRequest)
    }
}
