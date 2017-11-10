//
//  StepicsAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.08.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

class StepicsAPI {
    let name = "stepics"
    let manager: Alamofire.SessionManager

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        manager = Alamofire.SessionManager(configuration: configuration)
    }

    func retrieveCurrentUser() -> Promise<User> {
        return Promise { fulfill, reject in
            manager.request("\(StepicApplicationsInfo.apiURL)/\(name)/1", parameters: nil, encoding: URLEncoding.default, headers: AuthInfo.shared.initialHTTPHeaders).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    reject(RetrieveError(error: error))
                case .success(let json):
                    let user = User(json: json["users"].arrayValue[0])
                    fulfill(user)
                }
            }
        }
    }
}

extension StepicsAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func retrieveCurrentUser(_ headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: @escaping (User) -> Void, error errorHandler: @escaping (Error) -> Void) -> Request? {
        retrieveCurrentUser().then { success($0) }.catch { errorHandler($0) }
        return nil
    }
}
