//
//  AdaptiveStepView.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 20/08/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

protocol AdaptiveStepsView: class {
    func addContentController(_ controller: UIViewController)
    func removeContentController(_ controller: UIViewController)

    func updateTitle(_ title: String)
}
