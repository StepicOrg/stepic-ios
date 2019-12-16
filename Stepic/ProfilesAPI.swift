//
//  ProfilesAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 24.07.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class ProfilesAPI: APIEndpoint {
    override var name: String { "profiles" }

    func retrieve(
        ids: [Int],
        existing: [Profile],
        headers: [String: String] = AuthInfo.shared.initialHTTPHeaders
    ) -> Promise<[Profile]> {
        self.getObjectsByIds(ids: ids, updating: existing)
    }

    func retrieve(id: Int, headers: [String: String] = AuthInfo.shared.initialHTTPHeaders) -> Promise<[Profile]> {
        self.getObjectsByIds(ids: [id], updating: Profile.fetchById(id) ?? [])
    }

    func update(_ profile: Profile) -> Promise<Profile> {
        self.update.request(
            requestEndpoint: self.name,
            paramName: "profile",
            updatingObject: profile,
            withManager: self.manager
        )
    }
}
