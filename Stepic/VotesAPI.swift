//
//  VotesAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 27.06.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class VotesAPI: APIEndpoint {
    override var name: String { return "votes" }

    func update(_ vote: Vote) -> Promise<Vote> {
        return update.request(requestEndpoint: "votes", paramName: "vote", updatingObject: vote, withManager: manager)
    }
}

extension VotesAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    func update(_ vote: Vote, success: @escaping ((Vote) -> Void), error errorHandler: @escaping ((String) -> Void)) {
        update(vote).done { success($0) }.catch { errorHandler($0.localizedDescription) }
    }
}
