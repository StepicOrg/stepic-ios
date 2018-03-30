//
//  FocusableCustomView.swift
//  StepikTV
//
//  Created by Александр Пономарев on 07.11.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

public protocol FocusAnimatable {
    func changeToDefault()
    func changeToFocused()
    func changeToHighlighted()
}

extension UIView {

    // Events to look for a Highlighted state
    override open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        guard presses.first!.type == UIPressType.select else {
            return
        }

        if let selfAnim = self as? FocusAnimatable {
            UIView.animate(withDuration: 0.1, animations: selfAnim.changeToHighlighted )
        }
    }

    override open func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesCancelled(presses, with: event)

        guard presses.first!.type == UIPressType.select else {
            return
        }

        if let selfAnim = self as? FocusAnimatable {
            UIView.animate(withDuration: 0.1, animations: selfAnim.changeToFocused )
        }
    }

    override open func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        guard presses.first!.type == UIPressType.select else {
            return
        }

        if let selfAnim = self as? FocusAnimatable {
            UIView.animate(withDuration: 0.1, animations: selfAnim.changeToFocused )
        }
    }

    func updateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // Mimik system focus/unfocus animation besides backgroundColor and title font

        guard let selfAnim = self as? FocusAnimatable else {
            return
        }

        if context.nextFocusedView == self {

            let animation: ((UIFocusAnimationContext) -> Void) = {
                let duration = $0.duration
                UIView.animate(withDuration: duration, animations: selfAnim.changeToFocused)
            }
            coordinator.addCoordinatedFocusingAnimations(animation, completion: nil)

        } else if context.previouslyFocusedView == self {

            let animation: ((UIFocusAnimationContext) -> Void) = {
                let duration = $0.duration
                UIView.animate(withDuration: duration, animations: selfAnim.changeToDefault)
            }
            coordinator.addCoordinatedUnfocusingAnimations( animation, completion: nil)
        }
    }
}

class FocusableCustomView: UIView, FocusAnimatable {

    override var canBecomeFocused: Bool {
        return true
    }

    func changeToDefault() {
        self.transform = CGAffineTransform.identity
        self.layer.cornerRadius = 6
        self.layer.shadowOpacity = 0.0
    }

    func changeToFocused() {
        self.transform = CGAffineTransform(scaleX: 1.09, y: 1.09)
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: 40)
        self.layer.shadowRadius = 30
        self.layer.shadowOpacity = 0.3
    }

    func changeToHighlighted() {
        self.transform = CGAffineTransform.identity
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowOpacity = 0.15
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        changeToDefault()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        changeToDefault()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        self.updateFocus(in: context, with: coordinator)
    }
}

class FocusableCustomTableViewCell: UITableViewCell, FocusAnimatable {

    override var canBecomeFocused: Bool {
        return true
    }

    func changeToDefault() {
        let color = UIColor.clear

        self.transform = CGAffineTransform.identity
        self.layer.shadowOpacity = 0.0
        self.backgroundColor = color
    }

    func changeToFocused() {
        let color = UIColor(red:0.50, green:0.79, blue:0.45, alpha:1.00)
        let scale = CGFloat(1.09)

        self.transform = CGAffineTransform(scaleX: scale, y: scale)
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.3
        self.backgroundColor = color
    }

    func changeToHighlighted() {
        self.transform = CGAffineTransform.identity
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowOpacity = 0.15
    }

    func initStyle() {
        setRoundedCorners(cornerRadius: 6)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initStyle()
        changeToDefault()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initStyle()
        changeToDefault()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        self.updateFocus(in: context, with: coordinator)
    }
}
