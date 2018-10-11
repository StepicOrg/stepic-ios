//
//  PersonalDeadlineNotificationsManager.swift
//  Stepic
//
//  Created by Ostrenkiy on 28.05.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UserNotifications

class PersonalDeadlineNotificationsManager {

    static var shared = PersonalDeadlineNotificationsManager()

    private let hoursBeforeDeadlineForNotification: [Int] = [12, 36]

    func updateDeadlineNotifications(for course: Course) {
        if #available(iOS 10.0, *) {
            removeNotificationsFor(course: course)
            guard let deadlines = course.sectionDeadlines else {
                return
            }

            for deadline in deadlines {
                guard let section = course.sections.first(where: {$0.id == deadline.section}) else {
                    continue
                }
                for hoursBeforeDeadline in hoursBeforeDeadlineForNotification {
                    let fireDate = deadline.deadlineDate.addingTimeInterval(-Double(hoursBeforeDeadline) * 60 * 60) //Date().addingTimeInterval(60) //
                    scheduleNotificationWith(course: course, section: section, fireDate: fireDate, hoursBeforeDeadline: hoursBeforeDeadline)
                }
            }
        } else {
            AnalyticsReporter.reportEvent(AnalyticsEvents.PersonalDeadlines.notSupportedNotification)
        }
    }

    private func notificationIdentifier(section: Int, hoursBeforeDeadline: Int) -> String {
        return "personaldeadline_section_\(section)_hours_\(hoursBeforeDeadline)"
    }

    @available(iOS 10.0, *)
    private func removeNotificationsFor(course: Course) {
        var identifiers: [String] = []
        for hours in hoursBeforeDeadlineForNotification {
            identifiers += course.sectionsArray.map {
                notificationIdentifier(section: $0, hoursBeforeDeadline: hours)
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    @available(iOS 10.0, *)
    private func scheduleNotificationWith(course: Course, section: Section, fireDate: Date, hoursBeforeDeadline: Int) {
        guard let timeZone = TimeZone(identifier: "UTC") else {
            return print("Unable to create TimeZone with UTC identifier")
        }

        let content = UNMutableNotificationContent()
        content.title = "\(course.title)"
        content.body = NSString.localizedUserNotificationString(
            forKey: "PersonalDeadlineNotificationBody",
            arguments: ["\(section.title)", "\(hoursBeforeDeadline)"]
        )
        content.sound = UNNotificationSound.default()

        let dateComponents = Calendar.current.dateComponents(
            in: timeZone,
            from: fireDate
        )
        let components = DateComponents(
            calendar: Calendar.current,
            timeZone: timeZone,
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: dateComponents.hour,
            minute: dateComponents.minute,
            second: dateComponents.minute
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(section: section.id, hoursBeforeDeadline: hoursBeforeDeadline),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let error = error {
                print("error while registering notification \(error.localizedDescription)")
            }
        })
    }
}
