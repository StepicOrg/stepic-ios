//
//  LessonsPresenterImpl.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 24/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

protocol LessonsRouter: class {
    func showStepsForLessonWith(_ id: Int)
}

final class LessonsPresenterImpl: LessonsPresenter {

    private weak var view: LessonsView?
    private weak var router: LessonsRouter?

    private let topicId: String
    private let knowledgeGraph: KnowledgeGraph
    private var lessons = [LessonPlainObject]() {
        didSet {
            self.view?.setLessons(viewLessons(from: lessons))
        }
    }

    private let lessonsService: LessonsService
    private let courseService: CourseService
    private let enrollmentService: EnrollmentService

    private var topic: KnowledgeGraphVertex<String> {
        return knowledgeGraph[topicId]!.key
    }
    private var lessonsIds: [Int] {
        return topic.lessons.filter { $0.type == .theory }.map { $0.id }
    }
    private var coursesIds: [Int] {
        return topic.lessons.compactMap { Int($0.courseId) }
    }

    init(view: LessonsView, router: LessonsRouter, topicId: String,
         knowledgeGraph: KnowledgeGraph, lessonsService: LessonsService,
         courseService: CourseService, enrollmentService: EnrollmentService) {
        self.view = view
        self.router = router
        self.topicId = topicId
        self.knowledgeGraph = knowledgeGraph
        self.lessonsService = lessonsService
        self.courseService = courseService
        self.enrollmentService = enrollmentService
    }

    func refresh() {
        if lessons.isEmpty {
            obtainLessonsFromCache()
        } else {
            fetchLessons()
        }
        joinCoursesIfNeeded()
    }

    func selectLesson(with viewData: LessonsViewData) {
        router?.showStepsForLessonWith(viewData.id)
    }

    // MARK: - Private API

    private func joinCoursesIfNeeded() {
        guard !coursesIds.isEmpty else {
            return
        }

        courseService.obtainCourses(with: coursesIds).then { courses -> Promise<[Int]> in
            var ids = Set(self.coursesIds)
            courses.filter { $0.enrolled }.map { $0.id }.forEach { ids.remove($0) }

            return .value(Array(ids))
        }.then { ids -> Promise<[Course]> in
            guard !ids.isEmpty else {
                return .value([])
            }

            return self.courseService.fetchCourses(with: ids)
        }.then { courses in
            when(fulfilled: courses.map { self.joinCourse($0) })
        }.done { courses in
            print("Successfully joined courses with ids: \(courses.map { $0.id })")
        }.catch { [weak self] error in
            self?.displayError(error)
        }
    }

    private func joinCourse(_ course: Course) -> Promise<Course> {
        guard !course.enrolled else {
            return .value(course)
        }

        return enrollmentService.joinCourse(course)
    }

    private func obtainLessonsFromCache() {
        lessonsService.obtainLessons(with: lessonsIds).done { [weak self] lessons in
            self?.lessons = lessons
        }.catch { [weak self] error in
            self?.displayError(error)
        }
    }

    private func fetchLessons() {
        guard lessonsIds.count > 0 else {
            return
        }

        lessonsService.fetchLessons(with: lessonsIds).done { [weak self] lessons in
            self?.lessons = lessons
        }.catch { [weak self] error in
            self?.displayError(error)
        }
    }

    private func viewLessons(from lessons: [LessonPlainObject]) -> [LessonsViewData] {
        return lessons.map { LessonsViewData(id: $0.id, title: $0.title) }
    }

    private func displayError(_ error: Swift.Error) {
        view?.displayError(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
    }
}
