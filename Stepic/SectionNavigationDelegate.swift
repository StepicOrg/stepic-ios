//
//  SectionNavigationDelegate.swift
//  Stepic
//
//  Created by Alexander Karpov on 19.08.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

protocol SectionNavigationDelegate: AnyObject {
    func didRequestPreviousUnitPresentationForLessonInUnit(unitID: Unit.IdType)
    func didRequestNextUnitPresentationForLessonInUnit(unitID: Unit.IdType)
}
