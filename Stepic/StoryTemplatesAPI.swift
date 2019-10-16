//
//  StoryTemplatesAPI.swift
//  Stepic
//
//  Created by Ostrenkiy on 16.08.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit

final class StoryTemplatesAPI: APIEndpoint {
    override var name: String { return "story-templates" }

    func retrieve(isPublished: Bool?, language: ContentLanguage, maxVersion: Int, page: Int = 1) -> Promise<([Story], Meta)> {
        return Promise { seal in
            var params: Parameters = [
                "page": page,
                "language": language.languageString,
                "max_version": maxVersion
            ]

            if let isPublished = isPublished {
                params["is_published"] = isPublished ? "true" : "false"
            }

            retrieve.request(
                requestEndpoint: name,
                paramName: name,
                params: params,
                updatingObjects: [],
                withManager: manager
            ).done { stories, meta in
                seal.fulfill((stories, meta))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
