//
//  DeleteRequestMaker.swift
//  Stepic
//
//  Created by Ostrenkiy on 20.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class DeleteRequestMaker {
    func request(requestEndpoint: String, deletingId: Int, withManager manager: Alamofire.SessionManager) -> Promise<Void> {
        return Promise { fulfill, reject in
            checkToken().then {
                manager.request("\(StepicApplicationsInfo.apiURL)/\(requestEndpoint)/\(deletingId)", method: .delete, encoding: JSONEncoding.default).validate().responseSwiftyJSON { response in
                    switch response.result {
                    case .failure(let error):
                        reject(error)
                    case .success(_):
                        fulfill(())
                    }
                }
            }.catch {
                error in
                reject(error)
            }
        }
    }
}
