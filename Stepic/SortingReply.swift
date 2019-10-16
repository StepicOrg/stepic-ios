//
//  SortingReply.swift
//  Stepic
//
//  Created by Alexander Karpov on 27.01.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import SwiftyJSON
import UIKit

final class SortingReply: NSObject, Reply {
    var ordering: [Int]

    init(ordering: [Int]) {
        self.ordering = ordering
    }

    required init(json: JSON) {
        ordering = json["ordering"].arrayValue.map({ $0.intValue })
        super.init()
    }

    var dictValue: [String: Any] {
        return ["ordering": ordering]
    }
}
