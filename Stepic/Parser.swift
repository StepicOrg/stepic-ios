//
//  Parser.swift
//  Stepic
//
//  Created by Alexander Karpov on 16.09.15.
//  Copyright (c) 2015 Alex Karpov. All rights reserved.
//

import SwiftyJSON
import UIKit

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

final class Parser: NSObject {
    static var shared = Parser()

    override private init() {}

    func dateFromTimedateJSON(_ json: JSON) -> Date? {
        if let date = json.string {
            return Date(timeIntervalSince1970: TimeInterval(timeString: date))
        } else {
            return nil
        }
    }

    func timedateStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: date)
    }

    func codeFromURL(_ url: URL) -> String? {
        return url.getKeyVals()?["code"]
    }
}

extension URL {
    func getKeyVals() -> [String: String]? {
        var results = [String: String]()
        let keyValues = self.query?.components(separatedBy: "&")
        if keyValues?.count > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results.updateValue(kv[1], forKey: kv[0])
                }
            }
        }
        return results
    }
}
