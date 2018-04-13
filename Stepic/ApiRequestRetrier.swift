//
//  ApiRequestRetrier.swift
//  Stepic
//
//  Created by Ostrenkiy on 18.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//
import Foundation
import Alamofire
import PromiseKit

class ApiRequestRetrier: RequestRetrier, RequestAdapter {
    private func buildUserAgent() -> String {
        if let bundleId = Bundle.main.bundleIdentifier,
           let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String {
            let osVersion = ["\(DeviceInfo.current.OSVersion.major)",
                             "\(DeviceInfo.current.OSVersion.minor)",
                             "\(DeviceInfo.current.OSVersion.patch)"].joined(separator: ".")
            return "Stepik/\(version) (\(bundleId); build \(build); iOS \(osVersion))"
        }

        return "Stepik (iOS app)"
    }

    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest

        // Add user-agent header
        urlRequest.setValue(buildUserAgent(), forHTTPHeaderField: "User-Agent")

        // Add cookie/token headers
        for (headerField, value) in AuthInfo.shared.initialHTTPHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: headerField)
        }
        return urlRequest
    }

    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 && request.retryCount == 0 {
            checkToken().then {
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
