//
//  MathQuizViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 26.01.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit

class MathQuizViewController: QuizViewController {

    var textField = UITextField()

    let textFieldHeight = 32

    var dataset: String?
    var reply: MathReply?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.containerView.addSubview(textField)

        textField.snp.makeConstraints { make -> Void in
            make.top.equalTo(self.containerView).offset(8)
            make.bottom.equalTo(self.containerView)
            make.height.equalTo(textFieldHeight)
        }

        if #available(iOS 11.0, *) {
            textField.snp.makeConstraints { make -> Void in
                make.leading.equalTo(self.containerView.safeAreaLayoutGuide.snp.leading).offset(16)
                make.trailing.equalTo(self.containerView.safeAreaLayoutGuide.snp.trailing).offset(-16)
            }
        } else {
            textField.snp.makeConstraints { make -> Void in
                make.leading.equalTo(self.containerView).offset(16)
                make.trailing.equalTo(self.containerView).offset(-16)
            }
        }

        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.textColor = UIColor.mainText

        let tapG = UITapGestureRecognizer(target: self, action: #selector(MathQuizViewController.tap))
        self.view.addGestureRecognizer(tapG)

        textField.addTarget(self, action: #selector(MathQuizViewController.textFieldTextDidChange(textField:)), for: UIControl.Event.editingChanged)
    }

    @objc func textFieldTextDidChange(textField: UITextField) {
        switch presenter?.state ?? .nothing {
        case .attempt:
            break
        case .submission:
            presenter?.state = .attempt
        default:
            break
        }
    }

    @objc func tap() {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var needsToRefreshAttemptWhenWrong: Bool {
        return false
    }

    override func display(dataset: Dataset) {
        guard let dataset = dataset as? String else {
            return
        }

        self.dataset = dataset
        textField.text = ""
        textField.isEnabled = true
    }

    override func display(reply: Reply, withStatus status: SubmissionStatus) {
        guard let reply = reply as? MathReply else {
            return
        }

        self.reply = reply
        display(reply: reply)
        textField.isEnabled = status != .correct
    }

    override func display(reply: Reply) {
        guard let reply = reply as? MathReply else {
            return
        }

        textField.text = reply.formula
    }

    //Override this in the subclass
    override func getReply() -> Reply? {
        return MathReply(formula: textField.text ?? "")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
