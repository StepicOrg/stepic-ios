//
//  BaseRouter.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 13/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

typealias RouterNavigational = RouterDismissable & RouterPoppable

class BaseRouter {
    typealias DeriveViewControllerClosure = (UINavigationController) -> UIViewController

    let assemblyFactory: AssemblyFactory
    weak var navigationController: UINavigationController?

    // MARK: Init

    init(assemblyFactory: AssemblyFactory, navigationController: UINavigationController) {
        self.assemblyFactory = assemblyFactory
        self.navigationController = navigationController
    }

    // MARK: Navigation

    func pushViewController(derivedFrom deriveViewController: DeriveViewControllerClosure, animated: Bool = true) {
        guard let navigationController = navigationController else {
            return
        }
        let viewController = deriveViewController(navigationController)
        navigationController.pushViewController(viewController, animated: animated)
    }

    func presentModalNavigationController(derivedFrom deriveViewController: DeriveViewControllerClosure, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let navigationController = navigationController else {
            return
        }
        let viewController = deriveViewController(navigationController)
        presentModal(from: navigationController, to: viewController, animated: animated, completion: completion)
    }

    func presentModal(from viewControllerFromPresent: UIViewController, to viewControllerToPresent: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        viewControllerFromPresent.present(viewControllerToPresent, animated: animated, completion: completion)
    }
}

// MARK: - BaseRouter: RouterDismissable -

extension BaseRouter: RouterDismissable {
    func dismiss(completion: (() -> Void)?) {
        navigationController?.dismiss(animated: true, completion: completion)
    }

    func dismiss() {
        dismiss(completion: nil)
    }
}

// MARK: - BaseRouter: RouterPoppable -

extension BaseRouter: RouterPoppable {
    public func pop(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }

    public func popToRootViewController(animated: Bool) {
        navigationController?.popToRootViewController(animated: animated)
    }

    public func popToViewController(_ viewController: UIViewController, animated: Bool) {
        navigationController?.popToViewController(viewController, animated: animated)
    }
}
