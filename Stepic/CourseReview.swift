//
//  CourseReview.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 12/02/2019.
//  Copyright © 2019 Alex Karpov. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import PromiseKit

final class CourseReview: NSManagedObject, JSONSerializable, IDFetchable {
    typealias IdType = Int

    var json: JSON {
        return [
            "course": self.courseID,
            "user": self.userID,
            "score": self.score,
            "text": self.text
        ]
    }

    convenience required init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(_ json: JSON) {
        id = json["id"].intValue
        text = json["text"].stringValue
        userID = json["user"].intValue
        courseID = json["course"].intValue
        score = json["score"].intValue
        creationDate = Parser.sharedParser.dateFromTimedateJSON(json["create_date"]) ?? Date()
    }

    func update(json: JSON) {
        initialize(json)
    }

    static func fetch(courseID: Course.IdType) -> Guarantee<[CourseReview]> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CourseReview")
        let descriptor = NSSortDescriptor(key: "managedId", ascending: false)

        let predicate = NSPredicate(format: "managedCourseId == %@", courseID.fetchValue)

        request.predicate = predicate
        request.sortDescriptors = [descriptor]

        return Guarantee { seal in
            let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request, completionBlock: {
                results in
                guard let results = results.finalResult as? [CourseReview] else {
                    seal([])
                    return
                }
                seal(results)
            })
            _ = try? CoreDataHelper.instance.context.execute(asyncRequest)
        }
    }

    static func fetch(courseID: Course.IdType, userID: User.IdType) -> Guarantee<[CourseReview]> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CourseReview")
        let descriptor = NSSortDescriptor(key: "managedId", ascending: false)

        let courseIDPredicate = NSPredicate(format: "managedCourseId == %@", courseID.fetchValue)
        let userIDPredicate = NSPredicate(format: "managedUserId == %@", userID.fetchValue)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [courseIDPredicate, userIDPredicate])

        request.predicate = predicate
        request.sortDescriptors = [descriptor]

        return Guarantee { seal in
            let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request, completionBlock: { results in
                if let results = results.finalResult as? [CourseReview] {
                    seal(results)
                } else {
                    seal([])
                }
            })
            _ = try? CoreDataHelper.instance.context.execute(asyncRequest)
        }
    }
}
