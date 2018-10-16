//
//  StreakLocalNotificationContentProvider.swift
//  Stepic
//
//  Created by Ivan Magda on 15/10/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UserNotifications

final class StreakLocalNotificationContentProvider: LocalNotificationContentProvider {
    var title = ""

    var body: String {
        if #available(iOS 10.0, *) {
            return NSString.localizedUserNotificationString(forKey: "StreakNotificationAlertBody", arguments: nil)
        } else {
            return NSLocalizedString("StreakNotificationAlertBody", comment: "")
        }
    }

    var userInfo: [AnyHashable: Any] {
        return [
            NotificationsService.Keys.type.rawValue: NotificationsService.NotificationTypes.streak.rawValue
        ]
    }

    var identifier: String {
        return "\(NotificationsService.NotificationTypes.streak.rawValue)_local_notification"
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's UNNotificationSound.default()")
    var soundName: String {
        return "default_sound.wav"
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's `UNNotificationTrigger`")
    var repeatInterval: NSCalendar.Unit? {
        return .day
    }

    @available(iOS, introduced: 4.0, deprecated: 10.0, message: "Use UserNotifications Framework's `UNNotificationTrigger`")
    var fireDate: Date? {
        return calendar.date(from: dateComponents)
    }

    @available(iOS 10.0, *)
    var sound: UNNotificationSound {
        return UNNotificationSound(named: soundName)
    }

    @available(iOS 10.0, *)
    var trigger: UNNotificationTrigger? {
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }

    let UTCStartHour: Int
    let calendar: Calendar

    private var dateComponents: DateComponents {
        let timeZoneDiff = NSTimeZone.system.secondsFromGMT() / 3600
        var localStartHour = UTCStartHour + timeZoneDiff

        if localStartHour < 0 {
            localStartHour = 24 + localStartHour
        }
        if localStartHour > 23 {
            localStartHour = localStartHour - 24
        }

        let currentDate = Date()

        var components = DateComponents()
        components.year = calendar.component(.year, from: currentDate)
        components.month = calendar.component(.month, from: currentDate)
        components.day = calendar.component(.day, from: currentDate)
        components.hour = localStartHour
        components.minute = 0
        components.second = 0

        return components
    }

    init(UTCStartHour: Int, calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.UTCStartHour = UTCStartHour
        self.calendar = calendar
    }
}
