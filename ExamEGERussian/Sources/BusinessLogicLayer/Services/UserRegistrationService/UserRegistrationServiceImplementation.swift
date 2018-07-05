//
//  UserRegistrationServiceImplementation.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 04/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

final class UserRegistrationServiceImplementation: UserRegistrationService {

    // MARK: Instance Properties

    let authAPI: AuthAPI
    let stepicsAPI: StepicsAPI
    let profilesAPI: ProfilesAPI

    let defaultsStorageManager: DefaultsStorageManager
    
    // MARK: - Initializers
    
    init(authAPI: AuthAPI,
         stepicsAPI: StepicsAPI,
         profilesAPI: ProfilesAPI,
         defaultsStorageManager: DefaultsStorageManager
        ) {
        self.authAPI = authAPI
        self.stepicsAPI = stepicsAPI
        self.profilesAPI = profilesAPI
        self.defaultsStorageManager = defaultsStorageManager
    }
    
    // MARK: - UserRegistrationService
    
    func registerNewUser() -> Promise<User> {
        return Promise { seal in
            checkToken().then {
                self.registerUser()
            }.then { email, password -> Promise<User> in
                self.logInUser(email: email, password: password)
            }.then { user in
                self.unregisterFromEmail(user: user)
            }.done { user in
                seal.fulfill(user)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func logInUser(email: String, password: String) -> Promise<User> {
        defaultsStorageManager.accountEmail = email
        defaultsStorageManager.accountPassword = password
        
        return Promise { seal in
            self.authAPI.signInWithAccount(
                email: email,
                password: password
            ).then { token, authorizationType -> Promise<User> in
                AuthInfo.shared.token = token
                AuthInfo.shared.authorizationType = authorizationType
                
                return self.stepicsAPI.retrieveCurrentUser()
            }.done { user in
                AuthInfo.shared.user = user
                User.removeAllExcept(user)
                
                seal.fulfill(user)
            }.catch { error in
                print("ExamEgeRussian: failed to login user with error: \(error)")
                seal.reject(UserRegistrationServiceError.notLoggedIn)
            }
        }
    }
    
    // MARK: Private API
    
    private func registerUser() -> Promise<(email: String, password: String)> {
        if let savedEmail = defaultsStorageManager.accountEmail,
            let savedPassword = defaultsStorageManager.accountPassword {
            return .value((email: savedEmail, password: savedPassword))
        }
        
        let firstname = StringHelper.generateRandomString(of: 6)
        let lastname = StringHelper.generateRandomString(of: 6)
        let email = "exam_ege_russian_ios_\(Int(Date().timeIntervalSince1970))\(StringHelper.generateRandomString(of: 5))@stepik.org"
        let password = StringHelper.generateRandomString(of: 16)
        
        return Promise { seal in
            self.authAPI.signUpWithAccount(
                firstname: firstname,
                lastname: lastname,
                email: email,
                password: password
            ).done {
                seal.fulfill((email: email, password: password))
            }.catch { error in
                print("ExamEgeRussian: failed to register new user with error: \(error)")
                seal.reject(UserRegistrationServiceError.notRegistered)
            }
        }
    }

    private func unregisterFromEmail(user: User) -> Promise<User> {
        return Promise { seal in
            self.profilesAPI.retrieve(
                ids: [user.profile],
                existing: []
            ).then { profiles -> Promise<Profile> in
                if let profile = profiles.first {
                    profile.subscribedForMail = false
                    return self.profilesAPI.update(profile)
                } else {
                    print("ExamEGERussian: profile not found")
                    return Promise(error: UserRegistrationServiceError.noProfileFound)
                }
            }.done { _ in
                seal.fulfill(user)
            }.catch { error in
                print("ExamEGERussian: failed to unregister user from email with error: \(error)")
                seal.reject(UserRegistrationServiceError.notUnregisteredFromEmails)
            }
        }
    }
    
}
