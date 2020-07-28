import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

final class SocialProfilesAPI: APIEndpoint {
    override var name: String { "social-profiles" }

    /// Get social profiles by ids.
    func retrieve(ids: [Int], page: Int = 1) -> Promise<([SocialProfile], Meta)> {
        Promise { seal in
            let parameters: Parameters = [
                "ids": ids,
                "page": page
            ]
            
            self.retrieve.requestWithFetching(
                requestEndpoint: self.name,
                paramName: self.name,
                params: parameters,
                withManager: self.manager
            ).done { socialProfiles, meta, _ in
                seal.fulfill((socialProfiles, meta))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
