//
//  Assignment.swift
//  Stepic
//
//  Created by Alexander Karpov on 19.11.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import CoreData
import Foundation
import SwiftyJSON

@objc
final class Assignment: NSManagedObject, IDFetchable {
    typealias IdType = Int

    required convenience init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(_ json: JSON) {
        id = json["id"].intValue
        stepId = json["step"].intValue
        unitId = json["unit"].intValue
    }

    func update(json: JSON) {
        initialize(json)
    }
}
