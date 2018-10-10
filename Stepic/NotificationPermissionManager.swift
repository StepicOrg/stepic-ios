//
//  NotificationPermissionManager.swift
//  Stepic
//
//  Created by Ostrenkiy on 28.02.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UserNotifications
import PromiseKit

/// Defines whether the app is allowed to schedule notifications.
enum NotificationPermissionStatus {
    /// The user hasn't yet made a choice about whether is allowed the app to schedule notifications.
    case notDetermined
    /// The user not allowed the app to schedule or receive notifications.
    case denied
    /// The user allowed the app to schedule or receive notifications.
    case authorized

    // TODO: Test `Deliver Quietly` notifications on iOS 12.0 `case provisional`
    @available(iOS 10.0, *)
    init(_ authorizationStatus: UNAuthorizationStatus) {
        switch authorizationStatus {
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        default:
            self = .notDetermined
        }
    }
}

final class NotificationPermissionManager {
    func getCurrentPermissionStatus() -> Guarantee<NotificationPermissionStatus> {
        return Guarantee<NotificationPermissionStatus> { seal in
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    seal(NotificationPermissionStatus(settings.authorizationStatus))
                }
            } else {
                // Fallback on earlier versions, we can not determine if we denied push notifications or not
                if UIApplication.shared.isRegisteredForRemoteNotifications {
                    seal(.authorized)
                } else {
                    seal(.notDetermined)
                }
            }
        }
    }
}
