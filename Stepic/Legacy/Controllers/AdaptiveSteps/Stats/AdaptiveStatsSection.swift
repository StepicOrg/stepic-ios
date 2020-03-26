//
//  AdaptiveStatsSection.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 06.02.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

enum AdaptiveStatsSection {
    case progress
    case rating
    case achievements

    var localizedName: String {
        switch self {
        case .progress:
            return NSLocalizedString("AdaptiveProgress", comment: "")
        case .rating:
            return NSLocalizedString("AdaptiveRating", comment: "")
        case .achievements:
            return NSLocalizedString("AdaptiveAchievements", comment: "")
        }
    }
}
