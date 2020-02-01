//
//  AuthAPI.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 09.11.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Alamofire
import PromiseKit
import SwiftyJSON
import UIKit

enum SignInError: Error {
    case manyAttempts, noAppWithCredentials, invalidEmailAndPassword, badConnection
    case existingEmail(provider: String?, email: String?)
    case noEmail(provider: String?)
    case other(error: Error?, code: Int?, message: String?)
}

enum SignUpError: Error {
    var firstError: String? {
        switch self {
        case .validation(let email, let firstName, let lastName, let password):
            return [email, firstName, lastName, password].compactMap { $0 }.first
        default:
            return nil
        }
    }

    case validation(email: String?, firstName: String?, lastName: String?, password: String?)
    case other(error: Error?, code: Int?, message: String?)
}

enum TokenRefreshError: Error {
    case noAccess, noAppWithCredentials, other
}

final class AuthAPI {
    let manager: Alamofire.SessionManager

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        manager = Alamofire.SessionManager(configuration: configuration)
    }

    func signInWithCode(_ code: String) -> Promise<(StepikToken, AuthorizationType)> {
        Promise { seal in
            guard let socialInfo = StepikApplicationsInfo.social else {
                throw SignInError.noAppWithCredentials
            }

            let headers = [
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Basic \(socialInfo.credentials)"
            ]

            let params = [
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": socialInfo.redirectUri
            ]

            manager.request("\(StepikApplicationsInfo.oauthURL)/token/", method: .post, parameters: params, headers: headers).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    if let typedError = error as? URLError {
                        switch typedError.code {
                        case .notConnectedToInternet:
                            seal.reject(SignInError.badConnection)
                        default:
                            seal.reject(SignInError.other(error: typedError, code: nil, message: nil))
                        }
                    } else {
                        seal.reject(SignInError.other(error: error, code: nil, message: nil))
                    }
                case .success(let json):
                    let token = StepikToken(json: json)
                    seal.fulfill((token, AuthorizationType.code))
                }
            }
        }
    }

    func signInWithAccount(email: String, password: String) -> Promise<(StepikToken, AuthorizationType)> {
        Promise { seal in
            guard let passwordInfo = StepikApplicationsInfo.password else {
                throw SignInError.noAppWithCredentials
            }

            let headers = [
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Basic \(passwordInfo.credentials)"
            ]

            let params = [
                "grant_type": "password",
                "password": password,
                "username": email
            ]

            manager.request("\(StepikApplicationsInfo.oauthURL)/token/", method: .post, parameters: params, headers: headers).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    if let typedError = error as? URLError {
                        switch typedError.code {
                        case .notConnectedToInternet:
                            seal.reject(SignInError.badConnection)
                        default:
                            seal.reject(SignInError.other(error: typedError, code: nil, message: nil))
                        }
                    } else {
                        seal.reject(SignInError.other(error: error, code: nil, message: nil))
                    }
                case .success(let json):
                    if let r = response.response,
                        !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 497:
                            seal.reject(SignInError.manyAttempts)
                        case 401:
                            seal.reject(SignInError.invalidEmailAndPassword)
                        default:
                            seal.reject(SignInError.other(error: nil, code: r.statusCode, message: json["error"].string))
                        }
                    }

                    let token = StepikToken(json: json)
                    seal.fulfill((token, AuthorizationType.password))
                }
            }
        }
    }

    func refreshToken(with refresh_token: String, authorizationType: AuthorizationType) -> Promise<StepikToken> {
        func logRefreshError(statusCode: Int?, message: String?) {
            var parameters: [String: String] = [:]
            if let code = statusCode { parameters["code"] = "\(code)" }
            if let m = message { parameters["message"] = m }
            AnalyticsReporter.reportEvent(AnalyticsEvents.Errors.tokenRefresh, parameters: parameters)
        }

        return Promise { seal in
            var credentials = ""
            switch authorizationType {
            case .none:
                throw TokenRefreshError.other
            case .code:
                guard let socialInfo = StepikApplicationsInfo.social else {
                    throw TokenRefreshError.noAppWithCredentials
                }
                credentials = socialInfo.credentials
            case .password:
                guard let passwordInfo = StepikApplicationsInfo.password else {
                    throw TokenRefreshError.noAppWithCredentials
                }
                credentials = passwordInfo.credentials
            }

            let headers = [
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Basic \(credentials)"
            ]

            let params: Parameters = [
                "grant_type": "refresh_token",
                "refresh_token": refresh_token
            ]

            manager.request("\(StepikApplicationsInfo.oauthURL)/token/", method: .post, parameters: params, headers: headers).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    logRefreshError(statusCode: response.response?.statusCode, message: "Error \(error.localizedDescription) while refreshing")
                    seal.reject(TokenRefreshError.other)
                case .success(let json):
                    let token = StepikToken(json: json)
                    if token.accessToken.isEmpty {
                        logRefreshError(statusCode: response.response?.statusCode, message: "Error after getting empty access token")
                        if response.response?.statusCode == 401 {
                            seal.reject(TokenRefreshError.noAccess)
                        } else {
                            seal.reject(TokenRefreshError.other)
                        }
                    }

                    seal.fulfill(token)
                }
            }
        }
    }

    func signUpWithAccount(firstname: String, lastname: String, email: String, password: String) -> Promise<Void> {
        Promise { seal in
            // FIXME: AuthInfo dependency
            let headers = AuthInfo.shared.initialHTTPHeaders

            let params: Parameters = [
                "user": [
                    "first_name": firstname,
                    "last_name": lastname,
                    "email": email,
                    "password": password
                ]
            ]

            manager.request("\(StepikApplicationsInfo.apiURL)/users", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(SignUpError.other(error: error, code: nil, message: nil))
                case .success(let json):
                    if let r = response.response,
                        !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 400:
                            seal.reject(SignUpError.validation(email: json["email"].array?[0].string, firstName: json["first_name"].array?[0].string, lastName: json["last_name"].array?[0].string, password: json["password"].array?[0].string))
                        default:
                            seal.reject(SignUpError.other(error: nil, code: r.statusCode, message: json["error"].string))
                        }
                    }

                    seal.fulfill(())
                }
            }
        }
    }

    func signUpWithToken(socialToken: String, email: String?, provider: String) -> Promise<(StepikToken, AuthorizationType)> {
        Promise { seal in
            guard let socialInfo = StepikApplicationsInfo.social else {
                throw SignInError.noAppWithCredentials
            }

            var params: Parameters = [
                "provider": provider,
                "code": socialToken,
                "grant_type": "authorization_code",
                "redirect_uri": "\(socialInfo.redirectUri)",
                "code_type": "access_token"
            ]

            if email != nil {
                params["email"] = email!
            }

            let headers = [
                "Authorization": "Basic \(socialInfo.credentials)"
            ]

            manager.request("\(StepikApplicationsInfo.oauthURL)/social-token/", method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    if let typedError = error as? URLError {
                        switch typedError.code {
                        case .notConnectedToInternet:
                            seal.reject(SignInError.badConnection)
                        default:
                            seal.reject(SignInError.other(error: typedError, code: nil, message: nil))
                        }
                    } else {
                        seal.reject(SignInError.other(error: error, code: nil, message: nil))
                    }
                case .success(let json):
                    if json["error"] != JSON.null {
                        switch json["error"].stringValue {
                        case "social_signup_with_existing_email":
                            seal.reject(SignInError.existingEmail(provider: json["provider"].string, email: json["email"].string))
                        case "social_signup_without_email":
                            seal.reject(SignInError.noEmail(provider: json["provider"].string))
                        default:
                            seal.reject(SignInError.other(error: nil, code: response.response?.statusCode, message: json["error"].string))
                        }
                    }

                    let token = StepikToken(json: json)
                    seal.fulfill((token, AuthorizationType.code))
                }
            }
        }
    }
}

// Welcome to the legacy world!
// TODO: remove this extension after global refactoring
extension AuthAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func logInWithUsername(_ username: String, password: String, success : @escaping (_ token: StepikToken) -> Void, failure : @escaping (_ error: SignInError) -> Void) -> Request? {
        signInWithAccount(email: username, password: password).done { token, authorizationType in
            AuthInfo.shared.authorizationType = authorizationType
            success(token)
        }.catch { error in
            if let typedError = error as? SignInError {
                failure(typedError)
            } else {
                failure(SignInError.other(error: error, code: nil, message: nil))
            }
        }
        return nil
    }

    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult func refreshTokenWith(_ refresh_token: String, success : @escaping (_ token: StepikToken) -> Void, failure : @escaping (_ error: TokenRefreshError) -> Void) -> Request? {
        refreshToken(with: refresh_token, authorizationType: AuthInfo.shared.authorizationType).done { token in
            success(token)
        }.catch { error in
            if let typedError = error as? TokenRefreshError {
                failure(typedError)
            } else {
                failure(TokenRefreshError.other)
            }
        }
        return nil
    }
}
