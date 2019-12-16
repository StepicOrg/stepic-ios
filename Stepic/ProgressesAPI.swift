//
//  ProgressesAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 05.04.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class ProgressesAPI: APIEndpoint {
    override var name: String { "progresses" }

    @discardableResult
    func retrieve(
        ids: [Progress.IdType],
        headers: [String: String] = AuthInfo.shared.initialHTTPHeaders,
        existing: [Progress],
        refreshMode: RefreshMode,
        success: @escaping (([Progress]) -> Void),
        error errorHandler: @escaping ((NetworkError) -> Void)
    ) -> Request? {
        let ids = self.filterIds(ids)
        if ids.isEmpty {
            success([])
        }

        return getObjectsByIds(
            requestString: name,
            printOutput: false,
            ids: ids,
            deleteObjects: existing,
            refreshMode: refreshMode,
            success: success,
            failure: errorHandler
        )
    }

    @available(*, deprecated, message: "Legacy with update existing")
    func retrieve(
        ids: [Progress.IdType],
        headers: [String: String] = AuthInfo.shared.initialHTTPHeaders
    ) -> Promise<[Progress]> {
        let ids = self.filterIds(ids)
        if ids.isEmpty {
            return .value([])
        }

        return Promise { seal in
            Progress.fetchAsync(ids: ids).then { progresses in
                self.getObjectsByIds(ids: ids, updating: progresses)
            }.done { progresses in
                seal.fulfill(progresses)
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    private func filterIds(_ ids: [Progress.IdType]) -> [Progress.IdType] {
        ids.filter { !$0.isEmpty }
    }
}
