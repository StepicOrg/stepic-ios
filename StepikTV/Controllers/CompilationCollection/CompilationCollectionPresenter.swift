//
//  CompilationCollectionPresenter.swift
//  StepikTV
//
//  Created by Anton Kondrashov on 25/11/2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

class CompilationCollectionPresenter {

    let coursesAPI = CoursesAPI()

    private weak var view: CompilationCollectionView?
    private var courseListsAPI: CourseListsAPI
    private var courseListsCache: CourseListsCache

    private var lists: [CourseList] = []
    private var loaders: [CollectionRowLoader] = []
    private var rows: [CollectionRow] = []

    init(view: CompilationCollectionView, courseListsAPI: CourseListsAPI, courseListsCache: CourseListsCache) {
        self.view = view
        self.courseListsAPI = courseListsAPI
        self.courseListsCache = courseListsCache
    }

    func refresh() {
        let listLanguage = ContentLanguage.sharedContentLanguage
        print(listLanguage)
        refreshFromRemote(forLanguage: listLanguage)
    }

    private func refreshFromRemote(forLanguage language: ContentLanguage) {
        checkToken().then {
            [weak self]
            () -> Promise<([CourseList], Meta)> in
            guard let strongSelf = self else {
                throw WeakSelfError.noStrong
            }

            return strongSelf.courseListsAPI.retrieve(language: language, page: 1)
            }.then {
                [weak self]
                lists, _ -> Void in
                guard let strongSelf = self else {
                    throw WeakSelfError.noStrong
                }

                strongSelf.lists = lists.sorted { $0.position < $1.position }
                strongSelf.loaders = [
                    CollectionRowLoader(listType: .popular, title: "Popular"),
                    CollectionRowLoader(title: NSLocalizedString("Subjects", comment: ""))
                    ] + lists.map { CollectionRowLoader(listType: .collection(ids: $0.coursesArray), title: $0.title) }

                strongSelf.rows = strongSelf.loaders.map { strongSelf.buildRow(from: $0) }
                strongSelf.view?.setup(with: strongSelf.rows)

                strongSelf.loaders.enumerated().forEach { (index, loader) in

                    // Load courses for every non popular and non subjects collection row
                    loader.getCourses(withAPI: strongSelf.coursesAPI)?.then {
                        [weak self]
                        courses -> Void in
                        guard let strongSelf = self else {
                            throw WeakSelfError.noStrong
                        }

                        strongSelf.rows[index].setData(with: courses, for: strongSelf.view as! UIViewController)
                        strongSelf.view?.update(rowWith: index)
                    }.catch {
                        [weak self]
                        _ in
                        print("Error while refreshing collection")
                    }

                    // Load courses for popular courses row
                    loader.getPopular(withAPI: strongSelf.coursesAPI, language: language)?.then {
                        [weak self]
                        (courses, _) -> Void in
                        guard let strongSelf = self else {
                            throw WeakSelfError.noStrong
                        }

                        courses.forEach {
                            $0.loadAllInstructors {
                                [weak self] in
                                guard let strongSelf = self else { return }

                                strongSelf.rows[index].setData(with: courses, for: strongSelf.view as! UIViewController)
                                strongSelf.view?.update(rowWith: index)
                            }
                        }
                    }.catch {
                        [weak self]
                        _ in
                        print("Error while refreshing collection")
                    }

                    // Get tags for subjects row
                    if let tags = loader.getTags() {
                        strongSelf.rows[index].setData(with: tags, language: language, for: strongSelf.view as! UIViewController)
                        strongSelf.view?.update(rowWith: index)
                    }
                }
        }.catch {
            [weak self]
            error in
            guard let _ = self else { return }
            print(error.localizedDescription)
        }
    }

    private func buildRow(from loader: CollectionRowLoader) -> CollectionRow {
        guard let listType = loader.listType else { return CollectionRow(.narrow(title: loader.title)) }

        switch listType {
        case let .collection(ids: ids):
            return CollectionRow(.regular(title: loader.title), count: ids.count)
        case .popular:
            return CollectionRow(.major)
        default:
            fatalError()
        }
    }
}

struct CollectionRowLoader {
    var listType: CourseListType?
    let title: String

    init(title: String) {
        self.title = title
    }

    init(listType: CourseListType, title: String) {
        self.title = title
        self.listType = listType
    }

    func getCourses(withAPI coursesAPI: CoursesAPI) -> Promise<[Course]>? {
        guard let listType = listType else { return nil }

        switch listType {
        case let .collection(ids: ids):
            return listType.request(coursesWithIds: ids, withAPI: coursesAPI)
        default:
            return nil
        }
    }

    func getPopular(withAPI coursesAPI: CoursesAPI, language: ContentLanguage) -> Promise<([Course], Meta)>? {
        guard let listType = listType else { return nil }

        switch listType {
        case .popular:
            return coursesAPI.retrieve(excludeEnded: true, isPublic: true, order: "-activity", language: language, page: 1)
        default:
            return nil
        }
    }

    func getTags() -> [CourseTag]? {
        if listType == nil { return CourseTag.featuredTags }

        return nil
    }
}

enum CollectionRowType {
    case major
    case regular(title: String)
    case narrow(title: String)

    var viewClass: CollectionRowViewProtocol.Type {
        switch self {
        case .major:
            return MajorCollectionRowViewCell.self
        case .regular:
            return RegularCollectionRowViewCell.self
        case .narrow:
            return NarrowCollectionRowViewCell.self
        }
    }
}

class CollectionRow {
    let title: String?
    let count: Int
    let type: CollectionRowType

    var loaded: Bool = false

    init(_ type: CollectionRowType, count: Int = 5) {
        self.type = type
        self.count = count

        switch type {
        case let .regular(title: title):
            self.title = title
            data = [ItemViewData](repeating: ItemViewData(placeholder: #imageLiteral(resourceName: "placeholder")), count: count)
        case let .narrow(title: title):
            self.title = title
            data = [ItemViewData](repeating: ItemViewData(placeholder: #imageLiteral(resourceName: "tag-placeholder")), count: count)
        default:
            self.title = nil
            data = [ItemViewData](repeating: ItemViewData(placeholder: #imageLiteral(resourceName: "placeholder")), count: count)
        }
    }

    private(set) var data: [ItemViewData] = []

    func setData(with tags: [CourseTag], language: ContentLanguage, for viewController: UIViewController) {
        data = tags.map { tag in
            let title = tag.titleForLanguage[language]!.lowercased().firstUppercased
            return ItemViewData(placeholder: #imageLiteral(resourceName: "tag-placeholder"), id: tag.ID, title: title) {
                ScreensTransitions.moveToTagCoursesScreen(from: viewController, for: tag, title: title)
            }
        }

        loaded = true
    }

    func setData(with courses: [Course], for viewController: UIViewController) {
        data = courses.map { course in
            var hostname = ""
            if let host = course.instructors.first {
                hostname = "\(host.firstName) \(host.lastName) "
            }
            return ItemViewData(placeholder: #imageLiteral(resourceName: "placeholder"), imageURLString: course.coverURLString, id: course.id, title: course.title, subtitle: hostname) {
                guard course.enrolled else {
                    ScreensTransitions.moveToCourseInformationScreen(from: viewController, for: course)
                    return
                }
                ScreensTransitions.moveToCourseContent(from: viewController, for: course)
            }
        }

        loaded = true
    }
}

struct ItemViewData {
    let id: Int?
    let title: String

    var subtitle: String?
    var action: (() -> Void)?

    let placeholder: UIImage
    var backgroundImageURL: URL?

    var isEmpty: Bool = false

    init(placeholder: UIImage) {
        isEmpty = true
        title = ""

        self.id = nil
        self.placeholder = placeholder
    }

    init(placeholder: UIImage, id: Int, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.action = action

        self.placeholder = placeholder
    }

    init(placeholder: UIImage, imageURLString: String, id: Int, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.action = action

        self.placeholder = placeholder
        self.backgroundImageURL = URL(string: imageURLString)
    }
}
