//
//  SocialAuthProviders.swift
//  Stepic
//
//  Created by Alexander Karpov on 08.12.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import Foundation

enum SocialProvider: Int, CaseIterable {
    case vk
    case google
    case facebook
    case twitter
    case gitHub

    var info: SocialProviderInfo {
        switch self {
        case .vk:
            return SocialProviderInfo(
                name: self.name,
                amplitudeName: self.amplitudeName,
                image: #imageLiteral(resourceName: "vk"),
                registerURL: URL(string: "https://stepik.org/accounts/vk/login?next=%2Foauth2%2Fauthorize%2F%3Fclient_id%3D\(StepikApplicationsInfo.social!.clientId)%26response_type%3Dcode")!,
                socialSDKProvider: VKSocialSDKProvider.instance
            )
        case .google:
            return SocialProviderInfo(
                name: self.name,
                amplitudeName: self.amplitudeName,
                image: #imageLiteral(resourceName: "google"),
                registerURL: URL(string: "https://stepik.org/accounts/google/login?next=%2Foauth2%2Fauthorize%2F%3Fclient_id%3D\(StepikApplicationsInfo.social!.clientId)%26response_type%3Dcode")!
            )
        case .facebook:
            return SocialProviderInfo(
                name: self.name,
                amplitudeName: self.amplitudeName,
                image: #imageLiteral(resourceName: "fb"),
                registerURL: URL(string: "https://stepik.org/accounts/facebook/login?next=%2Foauth2%2Fauthorize%2F%3Fclient_id%3D\(StepikApplicationsInfo.social!.clientId)%26response_type%3Dcode")!,
                socialSDKProvider: FBSocialSDKProvider.instance
            )
        case .twitter:
            return SocialProviderInfo(
                name: self.name,
                amplitudeName: self.amplitudeName,
                image: #imageLiteral(resourceName: "twitter"),
                registerURL: URL(string: "https://stepik.org/accounts/twitter/login?next=%2Foauth2%2Fauthorize%2F%3Fclient_id%3D\(StepikApplicationsInfo.social!.clientId)%26response_type%3Dcode")!
            )
        case .gitHub:
            return SocialProviderInfo(
                name: self.name,
                amplitudeName: self.amplitudeName,
                image: #imageLiteral(resourceName: "github"),
                registerURL: URL(string: "https://stepik.org/accounts/github/login?next=%2Foauth2%2Fauthorize%2F%3Fclient_id%3D\(StepikApplicationsInfo.social!.clientId)%26response_type%3Dcode")!
            )
        }
    }

    var name: String {
        switch self {
        case .vk:
            return "VK"
        case .google:
            return "Google"
        case .facebook:
            return "Facebook"
        case .twitter:
            return "Twitter"
        case .gitHub:
            return "GitHub"
        }
    }

    var amplitudeName: String {
        switch self {
        case .vk:
            return "vk"
        case .google:
            return "google"
        case .facebook:
            return "facebook"
        case .twitter:
            return "twitter"
        case .gitHub:
            return "github"
        }
    }
}

struct SocialProviderInfo {
    var image: UIImage
    var registerURL: URL
    var name: String
    var socialSDKProvider: SocialSDKProvider?
    var amplitudeName: String

    init(
        name: String,
        amplitudeName: String,
        image: UIImage,
        registerURL: URL,
        socialSDKProvider: SocialSDKProvider? = nil
    ) {
        self.name = name
        self.image = image
        self.registerURL = registerURL
        self.socialSDKProvider = socialSDKProvider
        self.amplitudeName = amplitudeName
    }
}
