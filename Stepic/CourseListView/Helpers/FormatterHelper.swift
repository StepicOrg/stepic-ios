//
//  FormatterHelper.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 15.08.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

enum FormatterHelper {
    static func longNumber(_ number: Int) -> String {
        return number >= 1000
            ? "\(String(format: "%.1f", Double(number) / 1000.0))K"
            : "\(number)"
    }

    static func integerPercent(_ number: Int) -> String {
        return "\(number)%"
    }

    static func integerPercent(_ float: Float) -> String {
        return FormatterHelper.integerPercent(Int(float * 100))
    }

    static func averageRating(_ number: Float) -> String {
        return String(format: "%.2f", number)
    }

    static func coursesCount(_ count: Int) -> String {
        let pluralizedCountString = StringHelper.pluralize(
            number: count,
            forms: [
                NSLocalizedString("courses1", comment: ""),
                NSLocalizedString("courses234", comment: ""),
                NSLocalizedString("courses567890", comment: "")
            ]
        )
        return "\(count) \(pluralizedCountString)"
    }
}
