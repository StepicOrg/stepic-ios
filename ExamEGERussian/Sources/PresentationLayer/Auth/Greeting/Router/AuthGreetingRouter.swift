//
//  AuthorizationRouter.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 14/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

protocol AuthGreetingRouter: RouterDismissable {
    func showSignIn()
    func showSignUp()
}
