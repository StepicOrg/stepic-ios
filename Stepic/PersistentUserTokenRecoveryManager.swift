//
//  PersistentUserTokenRecoveryManager.swift
//  Stepic
//
//  Created by Alexander Karpov on 07.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

/*
 A PersistentRecoveryManager for StepicToken object
 */
final class PersistentUserTokenRecoveryManager: PersistentRecoveryManager {
    override func recoverObjectFromDictionary(_ dictionary: [String: Any]) -> DictionarySerializable? {
        return StepicToken(dictionary: dictionary)
    }

    func recoverStepicToken(userId: Int) -> StepicToken? {
        return recoverObjectWithKey("\(userId)") as? StepicToken
    }

    func writeStepicToken(_ token: StepicToken, userId: Int) {
        writeObjectWithKey("\(userId)", object: token)
    }
}
