//
//  AchievementProgressesAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 06.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit

final class AchievementProgressesAPI: APIEndpoint {
    override var name: String { "achievement-progresses" }

    func retrieve(user: Int, kind: String? = nil, sortByObtainDateDesc: Bool = false, page: Int = 1) -> Promise<([AchievementProgress], Meta)> {
        Promise { seal in
            var params = Parameters()
            if let kind = kind {
                params["kind"] = kind
            }
            params["user"] = user
            params["page"] = page
            if sortByObtainDateDesc {
                params["order"] = "-obtain_date"
            }

            retrieve.request(requestEndpoint: name, paramName: name, params: params, updatingObjects: [], withManager: manager).done { progresses, meta in
                seal.fulfill((progresses, meta))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
