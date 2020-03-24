//
//  Achievement.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 06.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import SwiftyJSON

final class Achievement: JSONSerializable {
    var id: Int
    var kind: String
    var targetScore: Int

    required init(json: JSON) {
        self.id = json["id"].intValue
        self.kind = json["kind"].stringValue
        self.targetScore = json["target_score"].intValue
    }

    func update(json: JSON) {
        self.id = json["id"].intValue
        self.kind = json["kind"].stringValue
        self.targetScore = json["target_score"].intValue
    }
}
