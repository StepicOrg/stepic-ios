//
//  ApiRequestRetrier.swift
//  Stepic
//
//  Created by Ostrenkiy on 18.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//
import Alamofire
import Foundation
import PromiseKit

final class ApiRequestRetrier: RequestRetrier, RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest

        for (headerField, value) in AuthInfo.shared.initialHTTPHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: headerField)
        }
        return urlRequest
    }

    func should(_ manager: Session, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 && request.retryCount == 0 {
            checkToken().done {
                completion(true, 0.0)
            }.catch {
                _ in
                completion(false, 0.0)
            }
        } else {
            completion(false, 0.0)
        }
    }
}
