//
//  AuthorizationSignUpPresenter.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 16/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

protocol AuthSignUpPresenter: class {
    func signUp(name: String, email: String, password: String)
    func cancel()
}
