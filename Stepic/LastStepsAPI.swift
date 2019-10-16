//
//  LastStepsAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 14.03.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

final class LastStepsAPI: APIEndpoint {
    override var name: String { return "last-steps" }

    @discardableResult func retrieve(ids: [String], headers: [String: String] = AuthInfo.shared.initialHTTPHeaders, updatingLastSteps: [LastStep], success: @escaping (([LastStep]) -> Void), error errorHandler: @escaping ((NetworkError) -> Void)) -> Request? {
        return getObjectsByIds(requestString: name, printOutput: false, ids: ids, deleteObjects: updatingLastSteps, refreshMode: .update, success: success, failure: errorHandler)
    }
}
