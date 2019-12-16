//
//  PersonalDeadlineLocalStorageManager.swift
//  Stepic
//
//  Created by Ostrenkiy on 29.05.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import SwiftyJSON

final class PersonalDeadlineLocalStorageManager {
    private let defaults = UserDefaults.standard

    private func defaultsKey(for course: Course) -> String { "personaldeadline_course_\(course.id)" }

    func deleteRecord(for course: Course) {
        let key = defaultsKey(for: course)
        defaults.setValue(nil, forKey: key)
    }

    func set(storageRecord: StorageRecord, for course: Course) {
        let key = defaultsKey(for: course)
        defaults.setValue(storageRecord.json.rawString(.utf8, options: .init(rawValue: 0)), forKey: key)
    }

    func getRecord(for course: Course) -> StorageRecord? {
        let key = defaultsKey(for: course)
        guard let jsonString = defaults.value(forKey: key) as? String else {
            return nil
        }
        let json = JSON(parseJSON: jsonString)
        return StorageRecord(json: json)
    }
}
