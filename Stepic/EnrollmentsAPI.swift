//
//  EnrollmentsAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 09.11.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class EnrollmentsAPI: APIEndpoint {
    override var name: String { "enrollments" }

    func delete(courseId: Int) -> Promise<Void> {
        self.delete.request(requestEndpoint: self.name, deletingId: courseId, withManager: manager)
    }
}

extension EnrollmentsAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    func joinCourse(_ course: Course, delete: Bool = false) -> Promise<Void> {
        Promise { seal in
            joinCourse(course, delete: delete, success: {
                seal.fulfill(())
            }, error: { _ in
                seal.reject(EnrollmentsAPIError.joinCourseFailed)
            })
        }
    }

    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult
    func joinCourse(
        _ course: Course,
        delete: Bool = false,
        success : @escaping () -> Void,
        error errorHandler: @escaping (String) -> Void
    ) -> Request? {
        let headers: [String: String] = AuthInfo.shared.initialHTTPHeaders
        let params: Parameters = [
            "enrollment": [
                "course": "\(course.id)"
            ]
        ]

        if !delete {
            return self.manager.request(
                "\(StepicApplicationsInfo.apiURL)/\(name)",
                method: .post,
                parameters: params,
                encoding: JSONEncoding.default,
                headers: headers
            ).responseSwiftyJSON({ response in
                var error = response.result.error
                var json: JSON = [:]
                if response.result.value == nil {
                    if error == nil {
                        error = NSError()
                    }
                } else {
                    json = response.result.value!
                }
                let response = response.response

                if let r = response {
                    if r.statusCode >= 200 && r.statusCode <= 299 {
                        if let courseJSON = json["courses"].array?[0] {
                            course.update(json: courseJSON)
                        }
                        success()
                    } else {
                        let s = NSLocalizedString("TryJoinFromWeb", comment: "")
                        errorHandler(s)
                    }
                } else {
                    let s = NSLocalizedString("Error", comment: "")
                    errorHandler(s)
                }
            })
        } else {
            return self.manager.request(
                "\(StepicApplicationsInfo.apiURL)/enrollments/\(course.id)",
                method: .delete,
                parameters: params,
                encoding: URLEncoding.default,
                headers: headers
            ).responseSwiftyJSON({ response in
                var error = response.result.error
                //                var json : JSON = [:]
                if response.result.value == nil {
                    if error == nil {
                        error = NSError()
                    }
                } else {
                    //                    json = response.result.value!
                }
                let response = response.response

                if let r = response {
                    if r.statusCode >= 200 && r.statusCode <= 299 {
                        success()
                        return
                    }
                }

                let s = NSLocalizedString("Error", comment: "")
                errorHandler(s)
            })
        }
    }
}

@available(*, deprecated, message: "Legacy error")
enum EnrollmentsAPIError: Error {
    case joinCourseFailed
}
