//
//  NotificationsAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 26.09.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class NotificationsAPI: APIEndpoint {
    override var name: String { return "notifications" }

    func retrieve(page: Int = 1, notificationType: NotificationType? = nil) -> Promise<( [Notification], Meta)> {
        var parameters = [
            "page": "\(page)"
        ]

        if let notificationType = notificationType {
            parameters["type"] = notificationType.rawValue
        }

        return retrieve.requestWithFetching(requestEndpoint: "notifications", paramName: "notifications", params: parameters, withManager: manager)
    }

    func update(_ notification: Notification) -> Promise<Notification> {
        return update.request(requestEndpoint: "notifications", paramName: "notification", updatingObject: notification, withManager: manager)
    }

    func markAllAsRead(headers: [String: String] = AuthInfo.shared.initialHTTPHeaders) -> Promise<()> {
        return Promise { seal in
            checkToken().done {
                self.manager.request("\(StepicApplicationsInfo.apiURL)/\(self.name)/mark-as-read", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseSwiftyJSON { response in
                    switch response.result {
                    case .failure(let error):
                        seal.reject(NetworkError(error: error))
                    case .success:
                        if response.response?.statusCode != 204 {
                            seal.reject(NetworkError.badStatus(204))
                        } else {
                            seal.fulfill(())
                        }
                    }
                }
            }.catch {
                error in
                seal.reject(error)
            }
        }
    }
}
