//
//  BranchService.swift
//  Stepic
//
//  Created by Ostrenkiy on 12/11/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import Branch

final class BranchService {
    private let deepLinkRoutingService: DeepLinkRoutingService

    init(deepLinkRoutingService: DeepLinkRoutingService) {
        self.deepLinkRoutingService = deepLinkRoutingService
    }

    func setup(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        Branch.getInstance().initSession(launchOptions: launchOptions) { params, _ in
            guard let data = params as? [String: AnyObject] else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.deepLinkRoutingService.route(DeepLinkRoute(data: data))
            }
        }
    }

    func openURL(userActivity: NSUserActivity) {
        Branch.getInstance()?.continue(userActivity)
    }

    func openURL(app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        Branch.getInstance().application(app, open: url, options: options)
    }

    func canOpenWithBranch(url: URL) -> Bool {
        return url.host == "stepik.app.link" || url.host == "stepik-alternate.app.link"
    }
}

// MARK: - DeepLinkRoute branch extension -
extension DeepLinkRoute {
    init?(data: [String: AnyObject]) {
        guard let screen = data["screen"] as? String else {
            return nil
        }

        switch screen {
        case "course":
            if let idString = data["course"] as? String,
               let id = Int(idString) {
                self = .course(courseID: id)
                return
            }
        default:
            return nil
        }
        return nil
    }
}
