//
//  CourseListPresenter.swift
//  Stepic
//
//  Created by Ostrenkiy on 10.10.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

protocol CourseListView: class {
    func display(courses: [CourseViewData])
    func update(courses: [CourseViewData])
    func setRefreshing(isRefreshing: Bool)
    func setLoadingNextPage(isLoading: Bool)
    func setNextPageEnabled(isEnabled: Bool)
}

class CourseListPresenter {
    private var coursesAPI: CoursesAPI
    private var progressesAPI: ProgressesAPI
    private var reviewSummariesAPI: CourseReviewSummariesAPI

    private weak var view: CourseListView?
    private var limit: Int?
    private var listType: CourseListType

    private var currentPage: Int = 1
    private var hasNextPage: Bool = false

    private var courses: [Course] = [] {
        didSet {
            self.view?.display(courses: CourseViewData.getData(from: courses))
        }
    }

    init(view: CourseListView, limit: Int?, listType: CourseListType, coursesAPI: CoursesAPI, progressesAPI: ProgressesAPI, reviewSummariesAPI: CourseReviewSummariesAPI) {
        self.view = view
        self.coursesAPI = coursesAPI
        self.progressesAPI = progressesAPI
        self.reviewSummariesAPI = reviewSummariesAPI
        self.limit = limit
        self.listType = listType
    }

    private func displayCachedAndRefresh(ids: [Int], isCollection: Bool) {
        displayCached(ids: ids)
        if isCollection {
            refreshCollection()
        } else {
            refresh()
        }
    }

    func refresh() {
        view?.setRefreshing(isRefreshing: true)
        switch listType {
        case let .enrolled(cachedIds: cachedIds), let .popular(cachedIds: cachedIds):
            displayCachedAndRefresh(ids: cachedIds, isCollection: false)
        case let .collection(ids: ids):
            displayCachedAndRefresh(ids: ids, isCollection: true)
        }
    }

    func loadNextPage() {
        self.view?.setLoadingNextPage(isLoading: true)
        coursesAPI.cancelAllTasks()
        listType.request(page: currentPage + 1, withAPI: coursesAPI)?.then {
            [weak self]
            (courses, meta) -> Void in
            self?.courses += courses
            self?.updateReviewSummaries(for: courses)
            self?.updateProgresses(for: courses)
            self?.currentPage = meta.page
            self?.hasNextPage = meta.hasNext
        }.always {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.view?.setLoadingNextPage(isLoading: false)
            strongSelf.view?.setNextPageEnabled(isEnabled: strongSelf.hasNextPage)
        }.catch {
            _ in
            print("error while loading next page")
        }
    }

    private func displayCached(ids: [Int]) {
        let recoveredCourses = try! Course.getCourses(ids)
        courses = Sorter.sort(recoveredCourses, byIds: ids)
    }

    private func refreshCollection() {
        if courses.isEmpty {
            self.view?.setRefreshing(isRefreshing: true)
        }
        coursesAPI.cancelAllTasks()
        switch listType {
        case let .collection(ids: ids):
            listType.request(coursesWithIds: ids, withAPI: coursesAPI)?.then {
                [weak self]
                courses -> Void in
                self?.courses = courses
                self?.updateReviewSummaries(for: courses)
                self?.updateProgresses(for: courses)
                self?.currentPage = 1
                self?.hasNextPage = false
            }.always {
                [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.view?.setRefreshing(isRefreshing: false)
                strongSelf.view?.setNextPageEnabled(isEnabled: strongSelf.hasNextPage)
            }.catch {
                _ in
                print("Error while refreshing collection")
            }
        default:
            break
        }

    }

    private func refreshNoCollection() {
        if courses.isEmpty {
            self.view?.setRefreshing(isRefreshing: true)
        }
        coursesAPI.cancelAllTasks()
        listType.request(page: 1, withAPI: coursesAPI)?.then {
            [weak self]
            (courses, meta) -> Void in
            self?.courses = courses
            self?.updateReviewSummaries(for: courses)
            self?.updateProgresses(for: courses)
            self?.currentPage = meta.page
            self?.hasNextPage = meta.hasNext
        }.always {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.view?.setRefreshing(isRefreshing: false)
            strongSelf.view?.setNextPageEnabled(isEnabled: strongSelf.hasNextPage)
        }.catch {
            _ in
            print("error while refreshing course collection")
        }
    }

    // Progresses

    private func updateProgresses(for courses: [Course]) {
        var progressIds: [String] = []
        var progresses: [Progress] = []
        for course in courses {
            if let progressId = course.progressId {
                progressIds += [progressId]
            }
            if let progress = course.progress {
                progresses += [progress]
            }
        }

        progressesAPI.getObjectsByIds(ids: progressIds, updating: progresses).then {
            [weak self]
            newProgresses -> Void in
            self?.matchProgresses(newProgresses: newProgresses, ids: progressIds, courses: courses)
            self?.view?.update(courses: CourseViewData.getData(from: courses))
        }.catch {
            _ in
            print("Error while loading progresses")
        }
    }

    private func matchProgresses(newProgresses: [Progress], ids progressIds: [String], courses: [Course]) {
        let progresses = Sorter.sort(newProgresses, byIds: progressIds)

        if progresses.count == 0 {
            CoreDataHelper.instance.save()
            return
        }

        var progressCnt = 0
        for i in 0 ..< courses.count {
            if courses[i].progressId == progresses[progressCnt].id {
                courses[i].progress = progresses[progressCnt]
                progressCnt += 1
            }
            if progressCnt == progresses.count {
                break
            }
        }
        CoreDataHelper.instance.save()
    }

    //Review summaries

    private func updateReviewSummaries(for courses: [Course]) {
        var reviewIds: [Int] = []
        var reviews: [CourseReviewSummary] = []
        for course in courses {
            if let reviewId = course.reviewSummaryId {
                reviewIds += [reviewId]
            }
            if let review = course.reviewSummary {
                reviews += [review]
            }
        }

        reviewSummariesAPI.getObjectsByIds(ids: reviewIds, updating: reviews).then {
            [weak self]
            newReviews -> Void in
            self?.matchReviewSummaries(newReviewSummaries: newReviews, ids: reviewIds, courses: courses)
            self?.view?.update(courses: CourseViewData.getData(from: courses))
        }.catch {
            _ in
            print("error while loading review summaries")
        }
    }

    private func matchReviewSummaries(newReviewSummaries: [CourseReviewSummary], ids reviewIds: [Int], courses: [Course]) {
        let reviews = Sorter.sort(newReviewSummaries, byIds: reviewIds)
        if reviews.count == 0 {
            CoreDataHelper.instance.save()
            return
        }

        var reviewCnt = 0
        for i in 0 ..< courses.count {
            if courses[i].reviewSummaryId == reviews[reviewCnt].id {
                courses[i].reviewSummary = reviews[reviewCnt]
                reviewCnt += 1
            }
            if reviewCnt == reviews.count {
                break
            }
        }
        CoreDataHelper.instance.save()
    }
}

struct CourseViewData {
    var title: String

    init(course: Course) {
        title = course.title
    }

    static func getData(from courses: [Course]) -> [CourseViewData] {
        return courses.map { CourseViewData(course: $0) }
    }
}

enum CourseListType {
    case enrolled(cachedIds: [Int])
    case popular(cachedIds: [Int])
    case collection(ids: [Int])

    func request(page: Int, withAPI coursesAPI: CoursesAPI) -> Promise<([Course], Meta)>? {
        switch self {
        case .enrolled(cachedIds: _):
            return coursesAPI.retrieve(featured: true, excludeEnded: true, isPublic: true, order: "-activity", page: page)
        case .popular(cachedIds: _):
            return coursesAPI.retrieve(featured: true, excludeEnded: true, isPublic: true, order: "-activity", page: page)
        default:
            return nil
        }
    }

    func request(coursesWithIds ids: [Int], withAPI coursesAPI: CoursesAPI) -> Promise<[Course]>? {
        switch self {
        case let .collection(ids: ids):
            return coursesAPI.retrieve(ids: ids, existing: try! Course.getCourses(ids))
        default:
            return nil
        }
    }
}
