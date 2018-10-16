//
//  NotificationsService.swift
//  Stepic
//
//  Created by Ivan Magda on 11/10/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UserNotifications
import PromiseKit
import SwiftyJSON

final class NotificationsService: NSObject {
    typealias NotificationUserInfo = [AnyHashable: Any]

    static let shared = NotificationsService()

    private let localNotificationsService: LocalNotificationsService
    private let routingService: DeepLinkRoutingService

    private var isInForeground: Bool {
        return UIApplication.shared.applicationState == .active
    }

    private override init() {
        self.localNotificationsService = LocalNotificationsService()
        self.routingService = DeepLinkRoutingService()

        super.init()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    func appDidFinishLaunching(with launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        if launchOptions?[.localNotification] != nil {
            let notification = launchOptions?[.localNotification] as? UILocalNotification
            didReceiveLocalNotification(with: notification?.userInfo)
            AmplitudeAnalyticsEvents.Launch.sessionStart(
                notificationType: notification?.userInfo?.notificationType
            ).send()
        } else if let userInfo = launchOptions?[.remoteNotification] as? NotificationUserInfo {
            didReceiveRemoteNotification(with: userInfo)
            AmplitudeAnalyticsEvents.Launch.sessionStart(
                notificationType: userInfo.notificationType
            ).send()
        } else {
            AmplitudeAnalyticsEvents.Launch.sessionStart().send()
        }
    }

    enum NotificationTypes: String {
        case streak
        case personalDeadline = "personal-deadline"
        case notifications
        case notificationStatuses = "notification-statuses"
        case achievementProgresses = "achievement-progresses"
    }
}

// MARK: - NotificationsService (LocalNotifications) -

extension NotificationsService {
    func scheduleLocalNotification(
        with contentProvider: LocalNotificationContentProvider,
        removeIdentical: Bool = true
    ) {
        NotificationPermissionManager().getCurrentPermissionStatus().then { status -> Promise<Void> in
            if !status.isRegistered {
                NotificationRegistrator.shared.registerForRemoteNotifications()
            }
            return .value(())
        }.then { _ -> Promise<Void> in
            if removeIdentical {
                self.removeLocalNotifications(withIdentifiers: [contentProvider.identifier])
            }

            return .value(())
        }.then {
            self.localNotificationsService.scheduleNotification(contentProvider: contentProvider)
        }.catch { error in
            print("Failed schedule local notification with error: \(error)")
        }
    }

    func removeAllLocalNotifications() {
        localNotificationsService.removeAllNotifications()
    }

    func removeLocalNotifications(withIdentifiers identifiers: [String]) {
        guard !identifiers.isEmpty else {
            return
        }

        localNotificationsService.removeNotifications(withIdentifiers: identifiers)
    }

    func didReceiveLocalNotification(with userInfo: NotificationUserInfo?) {
        print("Did receive local notification with info: \(userInfo ?? [:])")

        if isInForeground, let notificationType = userInfo?.notificationType {
            AmplitudeAnalyticsEvents.Notifications.received(notificationType: notificationType).send()
        }

        routeLocalNotification(with: userInfo)
    }

    private func routeLocalNotification(with userInfo: NotificationUserInfo?) {
        func routeToHome() {
            routingService.route(.home)
        }

        guard let userInfo = userInfo as? [String: Any],
              let key = userInfo[LocalNotificationsService.notificationKeyName] as? String else {
            return routeToHome()
        }

        if key.localizedCaseInsensitiveContains(NotificationTypes.streak.rawValue) {
            routeToHome()
        } else if key.localizedCaseInsensitiveContains(NotificationTypes.personalDeadline.rawValue) {
            guard let courseId = userInfo[PersonalDeadlineLocalNotificationContentProvider.Keys.course.rawValue] as? Int else {
                return routeToHome()
            }

            routingService.route(.course(courseID: courseId))
        } else {
            routeToHome()
        }
    }
}

// MARK: - NotificationsService (RemoteNotifications) -

extension NotificationsService {
    func didReceiveRemoteNotification(with userInfo: NotificationUserInfo) {
        print("remote notification received: DEBUG = \(userInfo)")

        guard let type = userInfo.notificationType else {
            return print("remote notification received: unable to parse notification type")
        }

        if isInForeground {
            AmplitudeAnalyticsEvents.Notifications.received(notificationType: type).send()
        }

        guard let notification = userInfo as? [String: Any] else {
            return print("remote notification received: unable to parse userInfo")
        }

        switch type {
        case NotificationTypes.notifications.rawValue:
            resolveRemoteNotificationsNotification(notification)
        case NotificationTypes.notificationStatuses.rawValue:
            resolveRemoteNotificationStatusesNotification(notification)
        case NotificationTypes.achievementProgresses.rawValue:
            resolveRemoteAchievementNotification(notification)
        default:
            print("remote notification received: unsopported notification type: \(type)")
        }
    }

    private func resolveRemoteNotificationsNotification(_ notificationDict: [String: Any]) {
        func postNotification(id: Int, isNew: Bool) {
            NotificationCenter.default.post(
                name: .notificationAdded,
                object: nil,
                userInfo: [Keys.id.rawValue: id, Keys.new.rawValue: isNew]
            )
        }

        guard let aps = notificationDict[Keys.aps.rawValue] as? [String: Any],
              let alert = aps[Keys.alert.rawValue]  as? [String: Any],
              let body = alert[Keys.body.rawValue] as? String,
              let object = notificationDict[Keys.object.rawValue] as? String else {
            return print("remote notification received: unable to parse notification: \(notificationDict)")
        }

        var notification: Notification
        let json = JSON(parseJSON: object)

        if let notificationId = json[Keys.id.rawValue].int,
           let fetchedNotification = Notification.fetch(id: notificationId) {
            fetchedNotification.update(json: json)
            notification = fetchedNotification
            postNotification(id: notification.id, isNew: false)
        } else {
            notification = Notification(json: json)
            postNotification(id: notification.id, isNew: true)
        }

        CoreDataHelper.instance.save()

        // Show alert for iOS 9.0 when the application is in foreground state.
        if #available(iOS 10.0, *) {
            NotificationReactionHandler().handle(with: notification)
        } else if isInForeground {
            NotificationAlertConstructor.sharedConstructor.presentNotificationFake(body, success: {
                NotificationReactionHandler().handle(with: notification)
            })
        } else {
            NotificationReactionHandler().handle(with: notification)
        }
    }

    private func resolveRemoteNotificationStatusesNotification(_ notificationDict: [String: Any]) {
        guard let aps = notificationDict[Keys.aps.rawValue] as? [String: Any],
              let badge = aps[Keys.badge.rawValue] as? Int else {
            return print("remote notification received: unable to parse notification: \(notificationDict)")
        }

        NotificationsBadgesManager.shared.set(number: badge)
    }

    private func resolveRemoteAchievementNotification(_ notificationDict: [String: Any]) {
        TabBarRouter(tab: .profile).route()
    }

    enum Keys: String {
        case type
        case aps
        case alert
        case body
        case object
        case id
        case new
        case badge
    }
}

// MARK: - NotificationsService: UNUserNotificationCenterDelegate -

@available(iOS 10.0, *)
extension NotificationsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .sound])
    }
}

private extension Dictionary where Key == AnyHashable {
    var notificationType: String? {
        return self[NotificationsService.Keys.type.rawValue] as? String
    }
}
