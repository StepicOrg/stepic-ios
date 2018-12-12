//
// RetentionLocalNotificationProvider.swift
// stepik-ios
//
// Created by Ivan Magda on 2018-12-07.
// Copyright 2018 Stepik. All rights reserved.
//

import Foundation
import UserNotifications

final class RetentionLocalNotificationProvider: LocalNotificationContentProvider {
    private let repetition: Repetition

    private var dateComponents: DateComponents? {
        let offset: Int
        switch self.repetition {
        case .nextDay:
            offset = 1
        case .thirdDay:
            offset = 3
        }

        let components: Set<Calendar.Component> = [.hour, .day, .month, .year]
        if let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) {
            return Calendar.current.dateComponents(components, from: date)
        } else {
            return nil
        }
    }

    var title: String {
        return self.repetition.notificationTitle
    }

    var body: String {
        return self.repetition.notificationText
    }

    var identifier: String {
        return "RetentionLocalNotification_\(self.repetition.rawValue)"
    }

    var fireDate: Date? {
        if let dateComponents = self.dateComponents {
            return Calendar.current.date(from: dateComponents)
        } else {
            return nil
        }
    }

    @available(iOS 10.0, *)
    var trigger: UNNotificationTrigger? {
        guard let dateComponents = self.dateComponents else {
            return nil
        }

        switch self.repetition {
        case .nextDay:
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        case .thirdDay:
            let timeInterval: TimeInterval
            if let date = Calendar.current.date(from: dateComponents) {
                timeInterval = date.timeIntervalSince(Date())
            } else {
                timeInterval = 3 * 24 * 60 * 60
            }
            return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: true)
        }
    }

    init(repetition: Repetition) {
        self.repetition = repetition
    }

    enum Repetition: String {
        case nextDay
        case thirdDay

        var notificationTitle: String {
            switch self {
            case .nextDay:
                return self.localized(for: "RetentionNotificationOnNextDayTitle")
            case .thirdDay:
                return self.localized(for: "RetentionNotificationOnThirdDayTitle")
            }
        }

        var notificationText: String {
            switch self {
            case .nextDay:
                return self.localized(for: "RetentionNotificationOnNextDayText")
            case .thirdDay:
                return self.localized(for: "RetentionNotificationOnThirdDayText")
            }
        }

        private func localized(for key: String) -> String {
            if #available(iOS 10.0, *) {
                return NSString.localizedUserNotificationString(forKey: key, arguments: nil)
            } else {
                return NSLocalizedString(key, comment: "")
            }
        }
    }
}

extension NotificationsService {
    private var retentionNotificationProviders: [RetentionLocalNotificationProvider] {
        return [.init(repetition: .nextDay), .init(repetition: .thirdDay)]
    }

    func scheduleRetentionNotifications() {
        if !PreferencesContainer.notifications.allowStreaksNotifications {
            self.retentionNotificationProviders.forEach { provider in
                self.scheduleLocalNotification(with: provider)
            }
        }
    }

    func removeRetentionNotifications() {
        let ids = self.retentionNotificationProviders.map { provider in
            provider.identifier
        }
        self.removeLocalNotifications(withIdentifiers: ids)
    }
}
