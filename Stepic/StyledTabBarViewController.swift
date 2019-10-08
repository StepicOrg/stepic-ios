//
//  StyledTabBarViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 03.09.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import UIKit

final class StyledTabBarViewController: UITabBarController {
    private let items = StepicApplicationsInfo.Modules.tabs?.compactMap { TabController(rawValue: $0)?.itemInfo } ?? []

    private var notificationsBadgeNumber: Int {
        get {
            if let tab = self.tabBar.items?.filter({ $0.tag == TabController.notifications.tag }).first {
                return Int(tab.badgeValue ?? "0") ?? 0
            }
            return 0
        }
        set {
            if let tab = self.tabBar.items?.filter({ $0.tag == TabController.notifications.tag }).first {
                tab.badgeValue = newValue > 0 ? "\(newValue)" : nil
                self.fixBadgePosition()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = UIColor.mainDark
        self.tabBar.unselectedItemTintColor = UIColor(hex: 0xbabac1)
        self.tabBar.isTranslucent = false

        self.setViewControllers(self.items.map {
            let vc = $0.controller
            vc.tabBarItem = $0.buildItem()
            return vc
        }, animated: false)
        self.updateTitlesForTabBarItems()

        self.delegate = self

        if !AuthInfo.shared.isAuthorized {
            self.selectedIndex = 1
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didBadgeUpdate(systemNotification:)),
            name: .badgeUpdated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didScreenRotate),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !DefaultsContainer.launch.didLaunch {
            DefaultsContainer.launch.didLaunch = true

            let onboardingViewController = ControllerHelper.instantiateViewController(
                identifier: "Onboarding",
                storyboardName: "Onboarding"
            )
            self.present(onboardingViewController, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private API

    @objc
    private func didBadgeUpdate(systemNotification: Foundation.Notification) {
        guard let userInfo = systemNotification.userInfo,
              let value = userInfo["value"] as? Int else {
            return
        }

        self.notificationsBadgeNumber = value
    }

    @objc
    private func didScreenRotate() {
        self.updateTitlesForTabBarItems()
        self.fixBadgePosition()
    }

    private func updateTitlesForTabBarItems() {
        func hideTitle(for item: UITabBarItem) {
            let inset: CGFloat = DeviceInfo.current.isPad ? 8.0 : 6.0
            item.imageInsets = UIEdgeInsets(top: inset, left: 0, bottom: -inset, right: 0)
            item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: CGFloat.greatestFiniteMagnitude)
        }

        func showDefaultTitle(for item: UITabBarItem) {
            item.imageInsets = UIEdgeInsets.zero
            item.titlePositionAdjustment = UIOffset.zero
        }

        self.tabBar.items?.forEach { item in
            if DeviceInfo.current.orientation.interface.isLandscape {
                // Using default tabbar in landscape
                showDefaultTitle(for: item)
            } else {
                if DeviceInfo.current.isPad {
                    // Using default tabbar on iPads in both orientations
                    showDefaultTitle(for: item)
                } else {
                    // Using tabbar w/o titles in other cases
                    hideTitle(for: item)
                }
            }
        }
    }

    private func fixBadgePosition() {
        for i in 1...items.count {
            if i >= tabBar.subviews.count { break }

            for badgeView in tabBar.subviews[i].subviews {
                if NSStringFromClass(badgeView.classForCoder) == "_UIBadgeView" {
                    badgeView.layer.transform = CATransform3DIdentity

                    if DeviceInfo.current.orientation.interface.isLandscape {
                        if DeviceInfo.current.isPlus {
                            badgeView.layer.transform = CATransform3DMakeTranslation(-2.0, 5.0, 1.0)
                        } else {
                            badgeView.layer.transform = CATransform3DMakeTranslation(1.0, 2.0, 1.0)
                        }
                    } else {
                        if DeviceInfo.current.isPad {
                            badgeView.layer.transform = CATransform3DMakeTranslation(1.0, 3.0, 1.0)
                        } else {
                            badgeView.layer.transform = CATransform3DMakeTranslation(-5.0, 3.0, 1.0)
                        }
                    }
                }
            }
        }
    }
}

extension StyledTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedIndex = tabBarController.viewControllers?.index(of: viewController),
              let eventName = self.items[safe: selectedIndex]?.clickEventName else {
            return
        }

        AnalyticsReporter.reportEvent(eventName)
    }
}

private struct TabBarItemInfo {
    var title: String
    var controller: UIViewController
    var clickEventName: String
    var image: UIImage
    var tag: Int

    func buildItem() -> UITabBarItem {
        return UITabBarItem(title: title, image: image, tag: tag)
    }
}

private enum TabController: String {
    case profile = "Profile"
    case home = "Home"
    case notifications = "Notifications"
    case explore = "Catalog"

    var tag: Int {
        return self.hashValue
    }

    var itemInfo: TabBarItemInfo {
        switch self {
        case .profile:
            return TabBarItemInfo(title: NSLocalizedString("Profile", comment: ""), controller: ControllerHelper.instantiateViewController(identifier: "ProfileNavigation", storyboardName: "Main"), clickEventName: AnalyticsEvents.Tabs.profileClicked, image: #imageLiteral(resourceName: "tab-profile"), tag: self.tag)
        case .home:
            let viewController = HomeAssembly().makeModule()
            let navigationViewController = StyledNavigationController(
                rootViewController: viewController
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Home", comment: ""),
                controller: navigationViewController,
                clickEventName: AnalyticsEvents.Tabs.myCoursesClicked,
                image: #imageLiteral(resourceName: "tab-home"),
                tag: self.tag
            )
       case .notifications:
            return TabBarItemInfo(title: NSLocalizedString("Notifications", comment: ""), controller: ControllerHelper.instantiateViewController(identifier: "NotificationsNavigation", storyboardName: "Main"), clickEventName: AnalyticsEvents.Tabs.notificationsClicked, image: #imageLiteral(resourceName: "tab-notifications"), tag: self.tag)
        case .explore:
            let viewController = ExploreAssembly().makeModule()
            let navigationViewController = StyledNavigationController(
                rootViewController: viewController
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Catalog", comment: ""),
                controller: navigationViewController,
                clickEventName: AnalyticsEvents.Tabs.catalogClicked,
                image: #imageLiteral(resourceName: "tab-explore"),
                tag: self.tag
            )
        }
    }
}
