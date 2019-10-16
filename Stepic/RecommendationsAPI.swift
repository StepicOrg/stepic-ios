//
//  RecommendationsAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 24.03.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

//TODO: Refactor this class into two separate API classes
final class RecommendationsAPI: APIEndpoint {
    override var name: String { return "recommendations" }
    var reactionName: String { return "recommendation-reactions" }

    func retrieve(course courseId: Int, count: Int = 1, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders) -> Promise<[Int]> {
        return Promise { seal in
            manager.request("\(StepicApplicationsInfo.apiURL)/\(self.name)", parameters: ["course": courseId, "count": count], headers: headers).validate(statusCode: [200]).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(NetworkError(error: error))
                case .success(let json):
                    seal.fulfill(json["recommendations"].arrayValue.compactMap { $0["lesson"].int })
                }
            }
        }
    }

    func sendReaction(user userId: Int, lesson lessonId: Int, reaction: Reaction, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders) -> Promise<Void> {
        let params = [
            "recommendationReaction": [
                "reaction": reaction.rawValue,
                "lesson": lessonId,
                "user": userId
            ]
        ]

        return Promise { seal in
            manager.request("\(StepicApplicationsInfo.apiURL)/\(self.reactionName)", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: [201]).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(NetworkError(error: error))
                case .success:
                    seal.fulfill(())
                }
            }
        }
    }
}

extension RecommendationsAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func sendRecommendationReaction(user userId: Int, lesson lessonId: Int, reaction: Reaction, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: @escaping (() -> Void), error errorHandler: @escaping ((String) -> Void)) -> Request? {
        sendReaction(user: userId, lesson: lessonId, reaction: reaction, headers: headers).done { _ in success() }.catch { error in errorHandler(error.localizedDescription) }
        return nil
    }

    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func getRecommendedLessonsId(course courseId: Int, count: Int = 1, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, success: @escaping (([Int]) -> Void), error errorHandler: @escaping ((String) -> Void)) -> Request? {
        retrieve(course: courseId, count: count, headers: headers).done { ids in success(ids) }.catch { error in errorHandler(error.localizedDescription) }
        return nil
    }
}

enum Reaction: Int {
    case solved = 2
    case interesting = 1
    case maybeLater = 0
    case neverAgain = -1
}
