//
//  ControllerHelper.swift
//  Stepic
//
//  Created by Alexander Karpov on 10.12.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import Foundation

struct ControllerHelper {
    static func getTopViewController() -> UIViewController? {
        var topVC = UIApplication.shared.keyWindow?.rootViewController
        while((topVC!.presentedViewController) != nil) {
            topVC = topVC!.presentedViewController
        }
        return topVC
    }

    static func instantiateViewController(identifier id: String, storyboardName: String = "Main") -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: id)
    }
}
