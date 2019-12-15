//
//  VKSocialSDKProvider.swift
//  Stepic
//
//  Created by Alexander Karpov on 21.11.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit
import VK_ios_sdk

protocol VKSocialSDKProviderDelegate: AnyObject {
    func presentAuthController(_ controller: UIViewController)
}

final class VKSocialSDKProvider: NSObject, SocialSDKProvider {
    weak var delegate: VKSocialSDKProviderDelegate?

    public static let instance = VKSocialSDKProvider()

    let name = "vk"

    private var sdkInstance: VKSdk

    override private init() {
        sdkInstance = VKSdk.initialize(withAppId: StepicApplicationsInfo.SocialInfo.AppIds.vk)
        super.init()
        sdkInstance.register(self)
        sdkInstance.uiDelegate = self
    }

    func getAccessInfo() -> Promise<(token: String, email: String?)> {
        return Promise { seal in
            getAccessInfo(success: { token, email in
                seal.fulfill((token: token, email: email))
            }, error: { error in
                seal.reject(error)
            })
        }
    }

    private func getAccessInfo(success successHandler: @escaping (String, String?) -> Void, error errorHandler: @escaping (SocialSDKError) -> Void) {
        self.successHandler = successHandler
        self.errorHandler = errorHandler

        if VKSdk.isLoggedIn() {
            VKSdk.forceLogout()
        }
        VKSdk.authorize(["email"])
    }

    private var successHandler: ((String, String?) -> Void)?
    private var errorHandler: ((SocialSDKError) -> Void)?
}

extension VKSocialSDKProvider: VKSdkDelegate {
    /**
     Notifies about access error. For example, this may occurs when user rejected app permissions through VK.com
     */
    public func vkSdkUserAuthorizationFailed() {
        print()
        errorHandler?(SocialSDKError.accessDenied)
    }

    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if result.error != nil {
            print(result.error)
            errorHandler?(SocialSDKError.connectionError)
            return
        }
        if let token = result.token.accessToken {
            successHandler?(token, result.token.email)
            return
        }
    }
}

extension VKSocialSDKProvider: VKSdkUIDelegate {
    public func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
    }

    func vkSdkShouldPresent(_ controller: UIViewController) {
        delegate?.presentAuthController(controller)
    }
}
