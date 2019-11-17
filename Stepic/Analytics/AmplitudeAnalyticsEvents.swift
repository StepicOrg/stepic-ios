//
//  AmplitudeAnalyticsEvents.swift
//  Stepic
//
//  Created by Ostrenkiy on 19.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

struct AmplitudeAnalyticsEvents {
    struct Launch {
        static var firstTime = AnalyticsEvent(name: "Launch first time")

        static func sessionStart(
            notificationType: String? = nil,
            sinceLastSession: TimeInterval
        ) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Session start",
                parameters: [
                    "notification_type": notificationType as Any,
                    "seconds_since_last_session": sinceLastSession
                ]
            )
        }
    }

    struct Onboarding {
        static func screenOpened(screen: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Onboarding screen opened",
                parameters: [
                    "screen": screen
                ]
            )
        }

        static func closed(screen: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Onboarding closed",
                parameters: [
                    "screen": screen
                ]
            )
        }

        static let completed = AnalyticsEvent(name: "Onboarding completed")
    }

    struct SignIn {
        static func loggedIn(source: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Logged in",
                parameters: [
                    "source": source
                ]
            )
        }
    }

    struct SignUp {
        static func registered(source: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Registered",
                parameters: [
                    "source": source
                ]
            )
        }
    }

    struct Course {
        static func joined(source: String, courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course joined",
                parameters: [
                    "source": source,
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }

        static func unsubscribed(courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course unsubscribed",
                parameters: [
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }

        static func continuePressed(source: String, courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Continue course pressed",
                parameters: [
                    "source": source,
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }
    }

    struct Steps {
        static func submissionMade(step: Int, type: String, language: String? = nil) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Submission made",
                parameters: [
                    "step": step,
                    "type": type,
                    "language": language as Any
                ]
            )
        }

        static func stepOpened(step: Int, type: String, number: Int? = nil) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Step opened",
                parameters: [
                    "step": step,
                    "type": type,
                    "number": number as Any
                ]
            )
        }
    }

    struct Downloads {
        static func started(content: Content) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Download started",
                parameters: [
                    "content": content.rawValue
                ]
            )
        }

        static func cancelled(content: Content) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Download cancelled",
                parameters: [
                    "content": content.rawValue
                ]
            )
        }

        static func deleted(content: Content, source: DeleteDownloadSource) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Download deleted",
                parameters: [
                    "content": content.rawValue,
                    "source": source.rawValue
                ]
            )
        }

        static func deleteDownloadsConfirmationInteracted(content: Content, isConfirmed: Bool) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Delete downloads confirmation interacted",
                parameters: [
                    "content": content.rawValue,
                    "result": isConfirmed ? "yes" : "no"
                ]
            )
        }

        static var downloadsScreenOpened = AnalyticsEvent(name: "Downloads screen opened")

        enum Content: String {
            case course
            case section
            case lesson
            case step
        }

        enum DeleteDownloadSource: String {
            case syllabus
            case downloads
        }
    }

    struct Search {
        static var started = AnalyticsEvent(name: "Course search started")

        static func searched(query: String, position: Int, suggestion: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course searched",
                parameters: [
                    "query": query,
                    "position": position,
                    "suggestion": suggestion
                ]
            )
        }
    }

    struct Notifications {
        static var screenOpened = AnalyticsEvent(name: "Notifications screen opened")

        static func receivedForeground(notificationType: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Foreground notification received",
                parameters: [
                    "notification_type": notificationType
                ]
            )
        }

        static func receivedInactive(notificationType: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Inactive notification received",
                parameters: [
                    "notification_type": notificationType
                ]
            )
        }

        static func defaultAlertShown(source: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Default notification alert shown",
                parameters: [
                    "source": source
                ]
            )
        }

        static func defaultAlertInteracted(source: String, result: InteractionResult) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Default notification alert interacted",
                parameters: [
                    "source": source,
                    "result": result.rawValue
                ]
            )
        }

        static func customAlertShown(source: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Custom notification alert shown",
                parameters: [
                    "source": source
                ]
            )
        }

        static func customAlertInteracted(source: String, result: InteractionResult) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Custom notification alert interacted",
                parameters: [
                    "source": source,
                    "result": result.rawValue
                ]
            )
        }

        static func preferencesAlertShown(source: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Preferences notification alert shown",
                parameters: [
                    "source": source
                ]
            )
        }

        static func preferencesAlertInteracted(source: String, result: InteractionResult) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Preferences notification alert interacted",
                parameters: [
                    "source": source,
                    "result": result.rawValue
                ]
            )
        }

        static func preferencesPushPermissionChanged(result: InteractionResult) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Preferences push permission changed",
                parameters: [
                    "result": result.rawValue
                ]
            )
        }

        enum InteractionResult: String {
            case yes
            case no
        }
    }

    struct Home {
        static var opened = AnalyticsEvent(name: "Home screen opened")
    }

    struct Catalog {
        static var opened = AnalyticsEvent(name: "Catalog screen opened")

        struct Category {
            static func opened(categoryID: Int, categoryNameEn: String) -> AnalyticsEvent {
                return AnalyticsEvent(
                    name: "Category opened ",
                    parameters: [
                        "category_id": categoryID,
                        "category_name_en": categoryNameEn
                    ]
                )
            }
        }
    }

    struct CourseList {
        static func opened(ID: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course list opened",
                parameters: [
                    "list_id": ID
                ]
            )
        }
    }

    struct Profile {
        static func opened(state: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Profile screen opened",
                parameters: [
                    "state": state
                ]
            )
        }
        static var editOpened = AnalyticsEvent(name: "Profile edit screen opened")

        static var editSaved = AnalyticsEvent(name: "Profile edit saved")
    }

    struct Certificates {
        static var opened = AnalyticsEvent(name: "Certificates screen opened")
    }

    struct Achievements {
        static func opened(isPersonal: Bool) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Achievements screen opened",
                parameters: [
                    "is_personal": isPersonal
                ]
            )
        }

        static func popupOpened(source: String, kind: String, level: Int? = nil) -> AnalyticsEvent {
            return popupEvent(name: "Achievement popup opened", source: source, kind: kind, level: level)
        }

        static func popupShared(source: String, kind: String, level: Int? = nil) -> AnalyticsEvent {
            return popupEvent(name: "Achievement share pressed", source: source, kind: kind, level: level)
        }

        private static func popupEvent(
            name: String,
            source: String,
            kind: String,
            level: Int? = nil
        ) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: name,
                parameters: [
                    "source": source,
                    "achievement_kind": kind,
                    "achievement_level": level as Any
                ]
            )
        }
    }

    struct Settings {
        static var opened = AnalyticsEvent(name: "Settings screen opened")

        static func fontSizeSelected(size: String) -> AnalyticsEvent {
            return AnalyticsEvent(name: "Font size selected", parameters: ["size": size])
        }
    }

    struct CoursePreview {
        static func opened(courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course preview screen opened",
                parameters: [
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }
    }

    struct Sections {
        static func opened(courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Sections screen opened",
                parameters: [
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }
    }

    struct Lessons {
        static func opened(sectionID: Int?) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Lessons screen opened",
                parameters: [
                    "section": sectionID as Any
                ]
            )
        }
    }

    struct CourseReviews {
        static func opened(courseID: Int, courseTitle: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Course reviews screen opened",
                parameters: [
                    "course": courseID,
                    "title": courseTitle
                ]
            )
        }
    }

    struct Discussions {
        enum DiscussionsSource: String {
            case discussion
            case reply
            case `default`
        }

        static func opened(source: DiscussionsSource) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Discussions screen opened",
                parameters: [
                    "source": source.rawValue
                ]
            )
        }
    }

    struct Stories {
        static func storyOpened(id: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Story opened",
                parameters: [
                    "id": id
                ]
            )
        }

        static func storyPartOpened(id: Int, position: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Story part opened",
                parameters: [
                    "id": id,
                    "position": position
                ]
            )
        }

        static func buttonPressed(id: Int, position: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Story button pressed",
                parameters: [
                    "id": id,
                    "position": position
                ]
            )
        }

        enum StoryCloseType: String {
            case cross, swipe, automatic
        }

        static func storyClosed(id: Int, type: StoryCloseType) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Story closed",
                parameters: [
                    "id": id,
                    "type": type.rawValue
                ]
            )
        }
    }

    struct PersonalDeadlines {
        static func created(weeklyLoadHours: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Personal deadline created",
                parameters: [
                    "hours": weeklyLoadHours
                ]
            )
        }

        static var buttonClicked = AnalyticsEvent(name: "Personal deadline schedule button pressed")
    }

    struct Video {
        static var continuedInBackground = AnalyticsEvent(name: "Video played in background")

        static func changedSpeed(source: String, target: String) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Video rate changed",
                parameters: [
                    "source": source,
                    "target": target
                ]
            )
        }
    }

    struct AdaptiveRating {
        static func opened(course: Int) -> AnalyticsEvent {
            return AnalyticsEvent(
                name: "Adaptive rating opened",
                parameters: ["course": course]
            )
        }
    }
}
