//
//  NotificationsService+PersonalDeadline.swift
//  Stepic
//
//  Created by Ivan Magda on 15/10/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UserNotifications

extension NotificationsService {
    private static let hoursBeforePersonalDeadlineNotification = [12, 36]

    func updatePersonalDeadlineNotifications(for course: Course) {
        guard let deadlines = course.sectionDeadlines else {
            return
        }

        for deadline in deadlines {
            guard let section = course.sections.first(where: { $0.id == deadline.section }) else {
                continue
            }
            for hoursBeforeDeadline in NotificationsService.hoursBeforePersonalDeadlineNotification {
                let fireDate = deadline.deadlineDate.addingTimeInterval(-Double(hoursBeforeDeadline) * 60 * 60)
                schedulePersonalDeadlineNotification(course: course, section: section, fireDate: fireDate, hoursBeforeDeadline: hoursBeforeDeadline)
            }
        }
    }

    private func schedulePersonalDeadlineNotification(
        course: Course,
        section: Section,
        fireDate: Date,
        hoursBeforeDeadline: Int
    ) {
        let contentProvider = PersonalDeadlineLocalNotificationContentProvider(
            course: course,
            section: section,
            deadlineDate: fireDate,
            hoursBeforeDeadline: hoursBeforeDeadline
        )
        scheduleLocalNotification(with: contentProvider, removeIdentical: true)
    }
}

final class PersonalDeadlineLocalNotificationContentProvider: LocalNotificationContentProvider {
    var title: String {
        return "\(course.title)"
    }

    var body: String {
        if #available(iOS 10.0, *) {
            return NSString.localizedUserNotificationString(
                forKey: "PersonalDeadlineNotificationBody",
                arguments: ["\(section.title)", "\(hoursBeforeDeadline)"]
            )
        } else {
            return String(
                format: NSLocalizedString("PersonalDeadlineNotificationBody", comment: ""),
                "\(section.title)", "\(hoursBeforeDeadline)"
            )
        }
    }

    var userInfo: [AnyHashable : Any]? {
        return [
            Keys.course.rawValue: course.id,
            Keys.section.rawValue: section.id,
            Keys.hoursBeforeDeadline: hoursBeforeDeadline
        ]
    }

    var identifier: String {
        return "\(NotificationsService.NotificationTypes.personalDeadline.rawValue)_section_\(section.id)_hours_\(hoursBeforeDeadline)"
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's UNNotificationSound.default()")
    var soundName: String {
        return UILocalNotificationDefaultSoundName
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's `UNNotificationTrigger`")
    var fireDate: Date? {
        return Calendar.current.date(from: dateComponents)
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's `UNNotificationTrigger`")
    var repeatInterval: NSCalendar.Unit? {
        return nil
    }

    @available(iOS 10.0, *)
    var sound: UNNotificationSound {
        return .default()
    }

    @available(iOS 10.0, *)
    var trigger: UNNotificationTrigger? {
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }

    private var dateComponents: DateComponents {
        let timeZone = TimeZone(identifier: "UTC") ?? .current

        let donorComponents = Calendar.current.dateComponents(
            in: timeZone,
            from: deadlineDate
        )
        let components = DateComponents(
            calendar: Calendar.current,
            timeZone: timeZone,
            year: donorComponents.year,
            month: donorComponents.month,
            day: donorComponents.day,
            hour: donorComponents.hour,
            minute: donorComponents.minute,
            second: 0
        )

        return components
    }

    let course: Course
    let section: Section
    let deadlineDate: Date
    let hoursBeforeDeadline: Int

    init(course: Course, section: Section, deadlineDate: Date, hoursBeforeDeadline: Int) {
        self.course = course
        self.section = section
        self.deadlineDate = deadlineDate
        self.hoursBeforeDeadline = hoursBeforeDeadline
    }

    enum Keys: String {
        case course
        case section
        case hoursBeforeDeadline
    }
}
