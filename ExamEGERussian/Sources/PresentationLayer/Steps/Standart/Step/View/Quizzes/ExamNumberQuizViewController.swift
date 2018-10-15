//
//  ExamNumberQuizViewController.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 15/08/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

final class ExamNumberQuizViewController: NumberQuizViewController {
    weak var logoutable: Logoutable?

    override func suggestStreak(streak: Int) {
    }

    override func showRateAlert() {
    }

    override func logout(onClose: (() -> Void)?) {
        logoutable?.logout { [weak self] in
            self?.presenter?.refreshAttempt()
        }
    }

    override func getReply() -> Reply? {
        guard let text = textField.text, !text.isEmpty else {
            return nil
        }

        return NumberReply(number: text)
    }

    override func initActivityView(color: UIColor) -> UIView {
        return super.initActivityView(color: .black)
    }
}
