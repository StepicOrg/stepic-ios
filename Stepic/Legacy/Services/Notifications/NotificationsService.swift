//
//  NotificationsService.swift
//  Stepic
//
//  Created by Ivan Magda on 11/10/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftyJSON
import UserNotifications

final class NotificationsService {
    typealias NotificationUserInfo = [AnyHashable: Any]

    private let localNotificationsService: LocalNotificationsService
    private let deepLinkRoutingService: DeepLinkRoutingService
    private let analytics: Analytics

    private var isInForeground: Bool {
        UIApplication.shared.applicationState == .active
    }

    init(
        localNotificationsService: LocalNotificationsService = LocalNotificationsService(),
        deepLinkRoutingService: DeepLinkRoutingService = DeepLinkRoutingService(),
        analytics: Analytics = StepikAnalytics.shared
    ) {
        self.localNotificationsService = localNotificationsService
        self.deepLinkRoutingService = deepLinkRoutingService
        self.analytics = analytics
        self.addObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func addObservers() {
        self.addOnWillResignActiveObserver()
    }

    func handleLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        NotificationPermissionStatus.current.done { status in
            AnalyticsUserProperties.shared.setPushPermissionStatus(status)
        }

        if let localNotification = launchOptions?[.localNotification] as? UILocalNotification {
            self.handleLocalNotification(with: localNotification.userInfo)
            self.reportSessionStart(userInfo: localNotification.userInfo)
        } else if let userInfo = launchOptions?[.remoteNotification] as? NotificationUserInfo {
            self.handleRemoteNotification(with: userInfo)
            self.reportSessionStart(userInfo: userInfo)
        } else {
            self.reportSessionStart(userInfo: nil)
        }
    }

    private func extractNotificationType(from userInfo: NotificationUserInfo?) -> String? {
        userInfo?[PayloadKey.type.rawValue] as? String
    }

    private func reportSessionStart(userInfo: NotificationUserInfo?) {
        self.analytics.send(
            .applicationDidLaunchWithOptions(
                notificationType: self.extractNotificationType(from: userInfo),
                secondsSinceLastSession: self.timeIntervalSinceLastActive
            )
        )
    }

    enum NotificationType: String {
        case streak
        case personalDeadline = "personal-deadline"
        case notifications
        case notificationStatuses = "notification-statuses"
        case achievementProgresses = "achievement-progresses"
        case retentionNextDay = "retention-next-day"
        case retentionThirdDay = "retention-third-day"
        case storyTemplates = "story-templates"
        case remindPurchaseCourse = "remind-purchase-course"
    }
}

// MARK: - NotificationsService (LocalNotifications) -

extension NotificationsService {
    func scheduleLocalNotification(
        with contentProvider: LocalNotificationContentProvider,
        removeIdentical: Bool = true
    ) {
        if removeIdentical {
            self.removeLocalNotifications(withIdentifiers: [contentProvider.identifier])
        }

        self.localNotificationsService.scheduleNotification(contentProvider: contentProvider).catch { error in
            print("Failed schedule local notification with error: \(error)")
        }
    }

    func removeAllLocalNotifications() {
        self.localNotificationsService.removeAllNotifications()
    }

    func removeLocalNotifications(withIdentifiers identifiers: [String]) {
        if !identifiers.isEmpty {
            self.localNotificationsService.removeNotifications(withIdentifiers: identifiers)
        }
    }

    func handleLocalNotification(with userInfo: NotificationUserInfo?) {
        print("Did receive local notification with info: \(userInfo ?? [:])")

        self.reportReceivedNotificationWithType(self.extractNotificationType(from: userInfo))

        if #available(iOS 10.0, *) {
            self.routeLocalNotification(with: userInfo)
        } else if self.isInForeground {
            guard let title = userInfo?[LocalNotificationsService.PayloadKey.title.rawValue] as? String,
                  let body = userInfo?[LocalNotificationsService.PayloadKey.body.rawValue] as? String else {
                return
            }

            LegacyNotificationsPresenter.present(text: title, subtitle: body, onTap: {
                self.routeLocalNotification(with: userInfo)
            })
        }
    }

    private func routeLocalNotification(with userInfo: NotificationUserInfo?) {
        func route(to route: DeepLinkRoute) {
            DispatchQueue.main.async {
                self.deepLinkRoutingService.route(route)
            }
        }

        guard let userInfo = userInfo as? [String: Any],
              let key = userInfo[LocalNotificationsService.PayloadKey.notificationName.rawValue] as? String else {
            return route(to: .home)
        }

        if key.localizedCaseInsensitiveContains(NotificationType.streak.rawValue) {
            route(to: .home)
        } else if key.localizedCaseInsensitiveContains(NotificationType.personalDeadline.rawValue) {
            if let courseID = userInfo[PersonalDeadlineLocalNotificationContentProvider.Key.course.rawValue] as? Int {
                route(to: .course(courseID: courseID))
            } else {
                route(to: .home)
            }
        } else if key.localizedCaseInsensitiveContains(NotificationType.remindPurchaseCourse.rawValue) {
            if let courseID = userInfo[PurchaseCourseLocalNotificationProvider.Key.course.rawValue] as? Int {
                route(to: .course(courseID: courseID))
            } else {
                route(to: .home)
            }
        } else {
            route(to: .home)
        }
    }

    private func reportReceivedNotificationWithType(_ notificationType: String?) {
        if let notificationType = notificationType {
            switch UIApplication.shared.applicationState {
            case .active:
                self.analytics.send(.foregroundNotificationReceived(notificationType: notificationType))
            case .inactive:
                self.analytics.send(.inactiveNotificationReceived(notificationType: notificationType))
            case .background:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - NotificationsService (RemoteNotifications) -

extension NotificationsService {
    func handleRemoteNotification(with userInfo: NotificationUserInfo) {
        print("remote notification received: DEBUG = \(userInfo)")

        guard let notificationTypeStringValue = self.extractNotificationType(from: userInfo) else {
            return print("remote notification received: unable to parse notification type")
        }

        self.reportReceivedNotificationWithType(notificationTypeStringValue)

        switch NotificationType(rawValue: notificationTypeStringValue) {
        case .notifications:
            self.resolveRemoteNotificationsNotification(userInfo)
        case .notificationStatuses:
            self.resolveRemoteNotificationStatusesNotification(userInfo)
        case .achievementProgresses:
            self.resolveRemoteAchievementNotification(userInfo)
        case .storyTemplates:
            self.resolveRemoteStoryTemplatesNotification(userInfo)
        default:
            print("remote notification received: unsupported notification type: \(notificationTypeStringValue)")
        }
    }

    private func resolveRemoteNotificationsNotification(_ userInfo: NotificationUserInfo) {
        func postNotification(id: Int, isNew: Bool) {
            NotificationCenter.default.post(
                name: .notificationAdded,
                object: nil,
                userInfo: [PayloadKey.id.rawValue: id, PayloadKey.new.rawValue: isNew]
            )
        }

        guard let aps = userInfo[PayloadKey.aps.rawValue] as? [String: Any],
              let alert = aps[PayloadKey.alert.rawValue] as? [String: Any],
              let body = alert[PayloadKey.body.rawValue] as? String,
              let object = userInfo[PayloadKey.object.rawValue] as? String else {
            return print("remote notification received: unable to parse notification: \(userInfo)")
        }

        var notification: Notification
        let json = JSON(parseJSON: object)

        if let notificationId = json[PayloadKey.id.rawValue].int,
           let fetchedNotification = Notification.fetch(id: notificationId) {
            fetchedNotification.update(json: json)
            notification = fetchedNotification
            postNotification(id: notification.id, isNew: false)
        } else {
            notification = Notification(json: json)
            postNotification(id: notification.id, isNew: true)
        }

        CoreDataHelper.shared.save()

        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                NotificationReactionHandler().handle(with: notification)
            } else if self.isInForeground {
                LegacyNotificationsPresenter.present(text: body, onTap: {
                    NotificationReactionHandler().handle(with: notification)
                })
            } else {
                NotificationReactionHandler().handle(with: notification)
            }
        }
    }

    private func resolveRemoteNotificationStatusesNotification(_ userInfo: NotificationUserInfo) {
        guard let aps = userInfo[PayloadKey.aps.rawValue] as? [String: Any],
              let badge = aps[PayloadKey.badge.rawValue] as? Int else {
            return print("remote notification received: unable to parse notification: \(userInfo)")
        }

        NotificationsBadgesManager.shared.set(number: badge)
    }

    private func resolveRemoteAchievementNotification(_ userInfo: NotificationUserInfo) {
        self.routeToProfile(userInfo: userInfo)
    }

    private func resolveRemoteStoryTemplatesNotification(_ userInfo: NotificationUserInfo) {
        guard let storyURL = userInfo[PayloadKey.storyURL.rawValue] as? String else {
            return print("remote notification received: unable to parse notification: \(userInfo)")
        }

        DispatchQueue.main.async {
            self.deepLinkRoutingService.route(path: storyURL)
        }
    }

    private func routeToProfile(userInfo: NotificationUserInfo) {
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                TabBarRouter(tab: .profile).route()
            } else if self.isInForeground {
                guard let aps = userInfo[PayloadKey.aps.rawValue] as? [String: Any],
                      let alert = aps[PayloadKey.alert.rawValue] as? [String: Any],
                      let body = alert[PayloadKey.body.rawValue] as? String else {
                    return
                }

                LegacyNotificationsPresenter.present(text: body, onTap: {
                    TabBarRouter(tab: .profile).route()
                })
            } else {
                TabBarRouter(tab: .profile).route()
            }
        }
    }

    enum PayloadKey: String {
        case type
        case aps
        case alert
        case body
        case object
        case id
        case new
        case badge
        case storyURL = "story_url"
    }
}

// MARK: - NotificationsService (LastActiveSession) -

extension NotificationsService {
    private static let lastActiveTimeIntervalKey = "lastActiveTimeIntervalKey"

    private var lastActiveTimeInterval: TimeInterval {
        get {
            UserDefaults.standard.value(
                forKey: NotificationsService.lastActiveTimeIntervalKey
            ) as? TimeInterval ?? Date().timeIntervalSince1970
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: NotificationsService.lastActiveTimeIntervalKey
            )
        }
    }

    private var timeIntervalSinceLastActive: TimeInterval {
        let now = Date()
        let lastActive = Date(timeIntervalSince1970: self.lastActiveTimeInterval)
        return now.timeIntervalSince(lastActive).rounded()
    }

    private func addOnWillResignActiveObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc
    private func onWillResignActive() {
        self.lastActiveTimeInterval = Date().timeIntervalSince1970
    }
}
