//
//  RegistrationPresenter.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 15.09.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

protocol RegistrationView: AnyObject {
    var state: RegistrationState { get set }

    func update(with result: RegistrationResult)
}

enum RegistrationResult {
    case success, error, badConnection
}

enum RegistrationState {
    case normal, loading, validationError(message: String)
}

final class RegistrationPresenter {
    weak var view: RegistrationView?

    var authAPI: AuthAPI
    var stepicsAPI: StepicsAPI
    var notificationStatusesAPI: NotificationStatusesAPI
    private let analytics: Analytics

    init(
        authAPI: AuthAPI,
        stepicsAPI: StepicsAPI,
        notificationStatusesAPI: NotificationStatusesAPI,
        analytics: Analytics = StepikAnalytics.shared,
        view: RegistrationView
    ) {
        self.authAPI = authAPI
        self.stepicsAPI = stepicsAPI
        self.notificationStatusesAPI = notificationStatusesAPI
        self.analytics = analytics

        self.view = view
    }

    func register(with name: String, email: String, password: String) {
        view?.state = .loading

        checkToken().then { () -> Promise<()> in
            self.authAPI.signUpWithAccount(firstname: name, lastname: " ", email: email, password: password)
        }.then { _ -> Promise<(StepikToken, AuthorizationType)> in
            self.authAPI.signInWithAccount(email: email, password: password)
        }.then { token, authorizationType -> Promise<User> in
            AuthInfo.shared.token = token
            AuthInfo.shared.authorizationType = authorizationType

            NotificationsRegistrationService().renewDeviceToken()

            return self.stepicsAPI.retrieveCurrentUser()
        }.then { user -> Promise<NotificationsStatus> in
            AuthInfo.shared.user = user
            User.removeAllExcept(user)

            self.analytics.send(.signUpSucceeded(source: .email))
            self.view?.update(with: .success)

            return self.notificationStatusesAPI.retrieve()
        }.done { result in
            NotificationsBadgesManager.shared.set(number: result.totalCount)
        }.catch { error in
            switch error {
            case PerformRequestError.noAccessToRefreshToken:
                AuthInfo.shared.token = nil
                self.view?.update(with: .error)
            case PerformRequestError.badConnection, SignInError.badConnection:
                self.view?.update(with: .badConnection)
            case is NetworkError:
                print("registration: successfully signed in, but could not get user")
                self.analytics.send(.signUpSucceeded(source: .email))
                self.view?.update(with: .success)
            case SignUpError.validation(_, _, _, _):
                if let message = (error as? SignUpError)?.firstError {
                    self.view?.state = .validationError(message: message)
                } else {
                    self.view?.update(with: .error)
                }
            default:
                self.view?.update(with: .error)
            }
        }
    }
}
