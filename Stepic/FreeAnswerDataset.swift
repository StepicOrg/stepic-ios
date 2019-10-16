//
//  FreeAnswerDataset.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.07.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import SwiftyJSON
import UIKit

final class FreeAnswerDataset: Dataset {
    var isHTMLEnabled: Bool
    var isAttachmentsEnabled: Bool

    required init(json: JSON) {
        isHTMLEnabled = json["is_html_enabled"].boolValue
        isAttachmentsEnabled = json["is_attachments_enabled"].boolValue
    }
}
