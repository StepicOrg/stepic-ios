//
//  AnalyticsUserProperties.swift
//  Stepic
//
//  Created by Ostrenkiy on 20.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import Amplitude_iOS
import Crashlytics

class AnalyticsUserProperties: AnalyticsUserPropertiesServiceProtocol {

    static let shared = AnalyticsUserProperties()

    func setProperty(key: String, value: Any?) {
        if let v = value {
            Amplitude.instance().setUserProperties([key: v])
        } else {
            let identify = AMPIdentify().unset(key)
            Amplitude.instance().identify(identify)
        }
    }

    private func setCrashlyticsProperty(key: String, value: Any?) {
        Crashlytics.sharedInstance().setObjectValue(value, forKey: key)
    }

    private func incrementAmplitudeProperty(key: String, value: Int = 1) {
        let identify = AMPIdentify().add(key, value: value as NSObject)
        Amplitude.instance().identify(identify)
    }

    func clearUserDependentProperties() {
        setUserID(to: nil)
        setCoursesCount(count: nil)
    }

    func setUserID(to id: Int?) {
        setProperty(key: "stepik_id", value: id)
        setCrashlyticsProperty(key: "stepik_id", value: id)
    }

    func incrementSubmissionsCount() {
        incrementAmplitudeProperty(key: "submissions_count")
    }

    func decrementCoursesCount() {
        incrementAmplitudeProperty(key: "courses_count", value: -1)
    }

    func incrementCoursesCount() {
        incrementAmplitudeProperty(key: "courses_count")
    }

    func setCoursesCount(count: Int?) {
        setProperty(key: "courses_count", value: count)
    }

    //Not supported yet, commented out
//    func setPushPermission(isGranted: Bool) {
//        setProperty(key: "push_permission", value: isGranted ? "granted" : "not_granted")
//    }

//    func setStreaksNotificationsEnabled(isEnabled: Bool) {
//        setProperty(key: "streaks_notifications_enabled", value: isEnabled ? "enabled" : "disabled")
//    }

    func setScreenOrientation(isPortrait: Bool) {
        setProperty(key: "screen_orientation", value: isPortrait ? "portrait" : "landscape")
    }

    func setApplicationID(id: String) {
        setProperty(key: "application_id", value: id)
    }

    func updateUserID() {
        self.setUserID(to: AuthInfo.shared.userId)
    }
}
