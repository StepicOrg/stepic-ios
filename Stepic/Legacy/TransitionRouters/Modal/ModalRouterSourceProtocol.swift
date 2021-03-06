//
//  ModalRouterSourceProtocol.swift
//  Stepic
//
//  Created by Ostrenkiy on 05.08.2018.
//  Copyright © 2018 Ostrenkiy. All rights reserved.
//

import UIKit

protocol ModalRouterSourceProtocol {
    func present(module: UIViewController, embedInNavigation: Bool, modalPresentationStyle: UIModalPresentationStyle)
}

protocol ModalStackRouterSourceProtocol {
    func present(moduleStack: [UIViewController], modalPresentationStyle: UIModalPresentationStyle)
}

extension UIViewController: ModalRouterSourceProtocol, ModalStackRouterSourceProtocol {
    @objc
    func present(
        module: UIViewController,
        embedInNavigation: Bool = false,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen
    ) {
        let moduleToPresent = embedInNavigation ? self.getEmbedded(moduleStack: [module]) : module
        moduleToPresent.modalPresentationStyle = modalPresentationStyle
        self.present(moduleToPresent, animated: true)
    }

    @objc
    func present(
        moduleStack: [UIViewController],
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen
    ) {
        let moduleToPresent = self.getEmbedded(moduleStack: moduleStack)
        moduleToPresent.modalPresentationStyle = modalPresentationStyle
        self.present(moduleToPresent, animated: true, completion: nil)
    }

    private func getEmbedded(moduleStack: [UIViewController]) -> UIViewController {
        let navigationController = StyledNavigationController()
        navigationController.setViewControllers(moduleStack, animated: false)

        let closeItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        closeItem.actionClosure = {
            navigationController.dismiss(animated: true, completion: nil)
        }
        moduleStack.last?.navigationItem.leftBarButtonItem = closeItem

        return navigationController
    }
}
