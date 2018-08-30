//
//  AdaptiveStepAssemblyProtocol.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 20/08/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

protocol AdaptiveStepsAssemblyProtocol: class {
    func module(topicId: String) -> UIViewController?
    func module(courseId: Int) -> UIViewController
}
