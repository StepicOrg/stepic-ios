import Foundation
import PromiseKit

protocol CourseListPersistenceServiceProtocol: AnyObject {
    func fetch() -> Promise<[Course]>
    func update(newCachedList: [Course])
}

final class CourseListPersistenceService: CourseListPersistenceServiceProtocol {
    let storage: CourseListPersistenceStorage

    init(storage: CourseListPersistenceStorage) {
        self.storage = storage
    }

    func fetch() -> Promise<[Course]> {
        let courseListIDs = self.storage.getCoursesList()

        return Promise { seal in
            Course.fetchAsync(courseListIDs).done { courses in
                var uniqueCourses: [Course] = []
                for course in courses {
                    if !uniqueCourses.contains(where: { $0.id == course.id }) {
                        uniqueCourses.append(course)
                    }
                }

                let courses = uniqueCourses.reordered(order: courseListIDs, transform: { $0.id })
                seal.fulfill(courses)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func update(newCachedList: [Course]) {
        let ids = newCachedList.map { $0.id }
        self.storage.update(newCachedList: ids)
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
