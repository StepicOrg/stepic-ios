//
//  ExploreAssembly.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 03.09.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

final class ExploreAssembly: Assembly {
    func makeModule() -> UIViewController {
        return ExploreViewController()
    }
}
