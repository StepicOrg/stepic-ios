//
//  DeepLinkRoutingService.swift
//  Stepic
//
//  Created by Ostrenkiy on 12.09.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import PromiseKit

final class DeepLinkRoutingService {
    private var window: UIWindow? {
        (UIApplication.shared.delegate as? AppDelegate)?.window
    }

    private var currentNavigation: UINavigationController? {
        guard let tabController = self.currentTabBarController else {
            return nil
        }

        let count = tabController.viewControllers?.count ?? 0
        let index = tabController.selectedIndex

        if index < count {
            return tabController.viewControllers?[tabController.selectedIndex] as? UINavigationController
        } else {
            return tabController.viewControllers?[0] as? UINavigationController
        }
    }

    private var currentTabBarController: UITabBarController? {
        self.window?.rootViewController as? UITabBarController
    }

    func route(path: String, from source: UIViewController? = nil) {
        self.route(DeepLinkRoute(path: path), fallbackPath: path, from: source)
    }

    func route(_ route: DeepLinkRoute?, fallbackPath: String = "", from source: UIViewController? = nil) {
        self.getModuleStack(route: route).done { moduleStack in
            let router = self.makeRouter(
                route: route,
                from: source,
                moduleStack: moduleStack,
                fallbackPath: fallbackPath
            )
            router.route()
        }.catch { _ in
            //TODO: Handle this
            print("network error during routing, handle this")
        }
    }

    private func makeRouter(
        route: DeepLinkRoute?,
        from source: UIViewController?,
        moduleStack: [UIViewController],
        fallbackPath: String
    ) -> RouterProtocol {
        guard let route = route else {
            return ModalOrPushStackRouter(
                source: source,
                destinationStack: moduleStack,
                embedInNavigation: false,
                fallbackPath: fallbackPath
            )
        }

        switch route {
        case .home:
            return TabBarRouter(tab: .home)
        case .catalog:
            return TabBarRouter(tab: .catalog)
        case .notifications(let section):
            return TabBarRouter(notificationsSection: section)
        case .course, .coursePromo, .discussions, .solutions, .lesson, .profile, .syllabus:
            return ModalOrPushStackRouter(
                source: source,
                destinationStack: moduleStack,
                embedInNavigation: true,
                fallbackPath: fallbackPath
            )
        }
    }

    private func getModuleStack(route: DeepLinkRoute?) -> Promise<[UIViewController]> {
        Promise { seal in
            guard let route = route else {
                seal.fulfill([])
                return
            }

            switch route {
            case .catalog, .notifications, .home:
                seal.fulfill([])
            case .profile(let userID):
                seal.fulfill([ProfileAssembly(userID: userID).makeModule()])
            case .course(let courseID), .coursePromo(let courseID):
                seal.fulfill([CourseInfoAssembly(courseID: courseID, initialTab: .info).makeModule()])
            case .syllabus(let courseID):
                seal.fulfill([CourseInfoAssembly(courseID: courseID, initialTab: .syllabus).makeModule()])
            case .lesson(let lessonID, let stepID, let unitID):
                DeepLinkRouter.routeToStepWithId(
                    stepID,
                    lessonId: lessonID,
                    unitID: unitID,
                    completion: { moduleStack in
                        seal.fulfill(moduleStack)
                    }
                )
            case .discussions(let lessonID, let stepID, let discussionID, let unitID):
                DeepLinkRouter.routeToDiscussionWithID(
                    discussionID: discussionID,
                    replyID: nil,
                    thread: DiscussionThread.ThreadType.default.rawValue,
                    lessonID: lessonID,
                    stepID: stepID,
                    unitID: unitID,
                    completion: { moduleStack in
                        seal.fulfill(moduleStack)
                    }
                )
            case .solutions(let lessonID, let stepID, let discussionID, let unitID):
                DeepLinkRouter.routeToDiscussionWithID(
                    discussionID: discussionID,
                    replyID: nil,
                    thread: DiscussionThread.ThreadType.solutions.rawValue,
                    lessonID: lessonID,
                    stepID: stepID,
                    unitID: unitID,
                    completion: { moduleStack in
                        seal.fulfill(moduleStack)
                    }
                )
            }
        }
    }
}
