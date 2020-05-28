//
//  DeepLinkRoute.swift
//  Stepic
//
//  Created by Ostrenkiy on 12/11/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import Regex

enum DeepLinkRoute {
    case lesson(lessonID: Int, stepID: Int, unitID: Int?)
    case notifications(section: NotificationsSection)
    case discussions(lessonID: Int, stepID: Int, discussionID: Int, unitID: Int?)
    case solutions(lessonID: Int, stepID: Int, discussionID: Int, unitID: Int?)
    case profile(userID: Int)
    case syllabus(courseID: Int)
    case catalog
    case home
    case course(courseID: Int)
    case coursePromo(courseID: Int)

    var path: String {
        let path: String

        switch self {
        case .lesson(let lessonID, let stepID, let unitID):
            if let unitID = unitID {
                path = "lesson/\(lessonID)/step/\(stepID)?unit=\(unitID)"
            } else {
                path = "lesson/\(lessonID)/step/\(stepID)"
            }
        case .notifications:
            path = "notifications"
        case .discussions(let lessonID, let stepID, let discussionID, let unitID):
            if let unitID = unitID {
                path = "lesson/\(lessonID)/step/\(stepID)?discussion=\(discussionID)&unit=\(unitID)"
            } else {
                path = "lesson/\(lessonID)/step/\(stepID)?discussion=\(discussionID)"
            }
        case .solutions(let lessonID, let stepID, let discussionID, let unitID):
            if let unitID = unitID {
                path = "lesson/\(lessonID)/step/\(stepID)?discussion=\(discussionID)&unit=\(unitID)&amp;thread=solutions"
            } else {
                path = "lesson/\(lessonID)/step/\(stepID)?discussion=\(discussionID)&amp;thread=solutions"
            }
        case .profile(let userID):
            path = "users/\(userID)"
        case .syllabus(let courseID):
            path = "course/\(courseID)/syllabus"
        case .catalog:
            path = "catalog"
        case .home:
            // TODO: Add regex pattern
            path = "home"
        case .course(let courseID):
            path = "course/\(courseID)"
        case .coursePromo(let courseID):
            path = "course/\(courseID)/promo"
        }

        return "\(StepikApplicationsInfo.stepikURL)/\(path)"
    }

    init?(path: String) {
        if let match = Pattern.catalog.regex.firstMatch(in: path),
           match.matchedString == path {
            self = .catalog
            return
        }

        if let match = Pattern.course.regex.firstMatch(in: path),
           let courseIDString = match.captures[0],
           let courseID = Int(courseIDString),
           match.matchedString == path {
            self = .course(courseID: courseID)
            return
        }

        if let match = Pattern.coursePromo.regex.firstMatch(in: path),
           let courseIDString = match.captures[0],
           let courseID = Int(courseIDString),
           match.matchedString == path {
            self = .coursePromo(courseID: courseID)
            return
        }

        if let match = Pattern.profile.regex.firstMatch(in: path),
           let userIDString = match.captures[0], let userID = Int(userIDString),
           match.matchedString == path {
            self = .profile(userID: userID)
            return
        }

        if let match = Pattern.notifications.regex.firstMatch(in: path),
           match.matchedString == path {
            self = .notifications(section: .all)
            return
        }

        if let match = Pattern.syllabus.regex.firstMatch(in: path),
           let courseIDString = match.captures[0],
           let courseID = Int(courseIDString),
           match.matchedString == path {
            self = .syllabus(courseID: courseID)
            return
        }

        if let match = Pattern.lesson.regex.firstMatch(in: path),
           let lessonIDString = match.captures[0], let lessonID = Int(lessonIDString),
           let stepIDString = match.captures[1], let stepID = Int(stepIDString),
           match.matchedString == path {
            let unitID = match.captures[2].flatMap { Int($0) }
            self = .lesson(lessonID: lessonID, stepID: stepID, unitID: unitID)
            return
        }

        if let match = Pattern.discussions.regex.firstMatch(in: path),
           let lessonIDString = match.captures[0], let lessonID = Int(lessonIDString),
           let stepIDString = match.captures[1], let stepID = Int(stepIDString),
           let discussionIDString = match.captures[2], let discussionID = Int(discussionIDString),
           match.matchedString == path {
            let unitID = match.captures[3].flatMap { Int($0) }
            self = .discussions(lessonID: lessonID, stepID: stepID, discussionID: discussionID, unitID: unitID)
            return
        }

        if let match = Pattern.solutions.regex.firstMatch(in: path),
           let lessonIDString = match.captures[0], let lessonID = Int(lessonIDString),
           let stepIDString = match.captures[1], let stepID = Int(stepIDString),
           let discussionIDString = match.captures[2], let discussionID = Int(discussionIDString),
           match.matchedString == path {
            let unitID = match.captures[3].flatMap { Int($0) }
            self = .solutions(lessonID: lessonID, stepID: stepID, discussionID: discussionID, unitID: unitID)
            return
        }

        return nil
    }

    enum Pattern {
        case catalog
        case course
        case coursePromo
        case profile
        case notifications
        case syllabus
        case lesson
        case discussions
        case solutions

        var regex: Regex {
            try! Regex(string: self.pattern, options: [.ignoreCase])
        }

        private var pattern: String {
            let stepik = #"https:\/\/stepik.org\/"#
            let course = #"(?:course\/|course\/[a-zа-я-]+|)(\d+)\/?"#
            let lesson = #"(?:lesson\/|lesson\/[a-zа-я-]+)(\d+)\/?"#
            let queryComponents = "(?:(?=[?])[a-zA-Zа-яА-Я0-9=?&._-]+)?"

            switch self {
            case .catalog:
                return #"\#(stepik)catalog\/?\#(queryComponents)"#
            case .course:
                return "\(stepik)\(course)\(queryComponents)"
            case .coursePromo:
                return #"\#(stepik)\#(course)(?:promo\/?)\#(queryComponents)"#
            case .profile:
                return #"\#(stepik)users\/(\d+)\/?\#(queryComponents)"#
            case .notifications:
                return #"\#(stepik)notifications\/?\#(queryComponents)"#
            case .syllabus:
                return #"\#(stepik)\#(course)syllabus\/?\#(queryComponents)"#
            case .lesson:
                return #"\#(stepik)\#(lesson)step\/(\d+)(?:\?unit=(\d+))?\/?"#
            case .discussions:
                return #"\#(stepik)\#(lesson)step\/(\d+)(?:\?discussion=(\d+))(?:\&unit=(\d+))?\/?\#(queryComponents)"#
            case .solutions:
                return #"\#(stepik)\#(lesson)step\/(\d+)(?:\?discussion=(\d+))(?:\&unit=(\d+))?&amp;thread=solutions.*"#
            }
        }
    }
}
