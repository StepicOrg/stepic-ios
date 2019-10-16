//
//  AttemptsAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 05.04.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class AttemptsAPI: APIEndpoint {
    override var name: String { return "attempts" }

    func create(stepName: String, stepId: Int) -> Promise<Attempt> {
        let attempt = Attempt(step: stepId)
        return Promise { seal in
            create.request(requestEndpoint: "attempts", paramName: "attempt", creatingObject: attempt, withManager: manager).done { attempt, json in
                guard let json = json else {
                    seal.fulfill(attempt)
                    return
                }
                attempt.initDataset(json: json["attempts"].arrayValue[0]["dataset"], stepName: stepName)
                seal.fulfill(attempt)
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    func retrieve(stepName: String, stepID: Int) -> Promise<([Attempt], Meta)> {
        return Promise { seal in
            self.retrieve(
                stepName: stepName,
                stepId: stepID,
                success: { attempts, meta in
                    seal.fulfill((attempts, meta))
                },
                error: {
                    seal.reject(NSError(domain: $0, code: -1, userInfo: nil))
                }
            )
        }
    }

    @discardableResult func retrieve(stepName: String, stepId: Int, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: @escaping ([Attempt], Meta) -> Void, error errorHandler: @escaping (String) -> Void) -> Request? {
        let headers = AuthInfo.shared.initialHTTPHeaders

        var params: Parameters = [:]
        params["step"] = stepId
        if let userid = AuthInfo.shared.userId {
            params["user"] = userid as NSObject?
        } else {
            print("no user id!")
        }

        return manager.request("\(StepicApplicationsInfo.apiURL)/attempts", method: .get, parameters: params, encoding: URLEncoding.default, headers: headers).responseSwiftyJSON({
            response in

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

            if let e = error {
                let d = (e as NSError).localizedDescription
                print(d)
                errorHandler(d)
                return
            }

            if response?.statusCode == 200 {
                let meta = Meta(json: json["meta"])
                let attempts = json["attempts"].arrayValue.map({ Attempt(json: $0, stepName: stepName) })
                success(attempts, meta)
                return
            } else {
                errorHandler("Response status code is wrong(\(String(describing: response?.statusCode)))")
                return
            }
        })
    }
}

extension AttemptsAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func create(stepName: String, stepId: Int, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: @escaping (Attempt) -> Void, error errorHandler: @escaping (String) -> Void) -> Request? {
        create(stepName: stepName, stepId: stepId).done {
            attempt in
            success(attempt)
        }.catch {
            error in
            errorHandler(error.localizedDescription)
        }
        return nil
    }
}
