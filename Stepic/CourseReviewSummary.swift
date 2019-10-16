//
//  CourseReviewSummary.swift
//  Stepic
//
//  Created by Ostrenkiy on 29.09.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import CoreData
import Foundation
import SwiftyJSON

final class CourseReviewSummary: NSManagedObject, JSONSerializable, IDFetchable {
    typealias IdType = Int

    required convenience init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(_ json: JSON) {
        id = json["id"].intValue
        average = json["average"].floatValue
        count = json["count"].intValue
        distribution = json["distribution"].arrayObject as! [Int]
    }

    func update(json: JSON) {
        initialize(json)
    }
}
