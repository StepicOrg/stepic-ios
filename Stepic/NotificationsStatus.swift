//
//  NotificationsStatus.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 23.11.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import SwiftyJSON

final class NotificationsStatus: JSONSerializable {
    var id: Int
    var learnCount: Int
    var reviewCount: Int
    var commentsCount: Int
    var teachCount: Int
    var defaultCount: Int
    var totalCount: Int

    func update(json: JSON) {
        self.id = json["id"].intValue
        self.learnCount = json["learn"].intValue
        self.reviewCount = json["review"].intValue
        self.commentsCount = json["comments"].intValue
        self.teachCount = json["teach"].intValue
        self.defaultCount = json["default"].intValue
        self.totalCount = json["total"].intValue
    }

    required init(json: JSON) {
        self.id = json["id"].intValue
        self.learnCount = json["learn"].intValue
        self.reviewCount = json["review"].intValue
        self.commentsCount = json["comments"].intValue
        self.teachCount = json["teach"].intValue
        self.defaultCount = json["default"].intValue
        self.totalCount = json["total"].intValue
    }
}
