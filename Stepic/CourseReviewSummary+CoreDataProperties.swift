//
//  CourseReviewSummary+CoreDataProperties.swift
//  Stepic
//
//  Created by Ostrenkiy on 29.09.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import CoreData
import Foundation

extension CourseReviewSummary {
    @NSManaged var managedDistribution: NSObject?
    @NSManaged var managedAverage: NSNumber?
    @NSManaged var managedCount: NSNumber?
    @NSManaged var managedId: NSNumber?

    @NSManaged var managedCourse: Course?

    static var oldEntity: NSEntityDescription {
        NSEntityDescription.entity(forEntityName: "CourseReviewSummary", in: CoreDataHelper.instance.context)!
    }

    convenience init() {
        self.init(entity: CourseReviewSummary.oldEntity, insertInto: CoreDataHelper.instance.context)
    }

    var id: Int {
        set(newId) {
            self.managedId = newId as NSNumber?
        }
        get {
             managedId?.intValue ?? -1
        }
    }

    var average: Float {
        get {
             managedAverage?.floatValue ?? 0
        }
        set(value) {
            managedAverage = value as NSNumber?
        }
    }

    var count: Int {
        get {
             managedCount?.intValue ?? 0
        }
        set(value) {
            managedCount = value as NSNumber?
        }
    }

    var distribution: [Int] {
        set(value) {
            self.managedDistribution = value as NSObject?
        }
        get {
             (self.managedDistribution as? [Int]) ?? []
        }
    }
}
