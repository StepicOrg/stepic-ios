//
//  NotificationStatusButton.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 10.10.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

final class NotificationStatusButton: UIButton {
    var unreadMark: UIView?

    enum Status {
        case unread, read
    }

    var status: Status = .read

    lazy var unreadMarkView: UIView = {
        let mark = UIView()
        mark.frame = CGRect(x: 11, y: -6, width: 12, height: 12)
        mark.clipsToBounds = true
        mark.layer.cornerRadius = 6
        mark.backgroundColor = self.unreadMarkColor
        return mark
    }()

    private let unreadMarkColor = UIColor.stepikGreen
    private let unreadMarkColorHightlighted = UIColor(red: 91 / 255, green: 183 / 255, blue: 91 / 255, alpha: 1.0)

    override func awakeFromNib() {
        setTitle("", for: .normal)
        backgroundColor = .clear
        clipsToBounds = false

        adjustsImageWhenDisabled = false
    }

    private func unreadMarkAnimation() {
        UIView.animate(withDuration: 0.45, animations: {
            self.unreadMark?.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.unreadMark?.removeFromSuperview()
            self.unreadMark = nil
        })
    }

    func update(with newStatus: Status) {
        switch newStatus {
        case .unread:
            self.setImage(UIImage(named: "notifications-letter-sign"), for: .normal)
            // read -> unread: add mark
            let markView = unreadMarkView
            markView.alpha = 0.0
            markView.transform = .identity
            unreadMark = markView
            addSubview(markView)
            UIView.animate(withDuration: 0.45, animations: {
                self.unreadMark?.alpha = 1.0
            })
        case .read:
            self.setImage(UIImage(named: "notifications-check-sign"), for: .normal)
            self.isEnabled = false
            if status == .unread {
                // unread -> read: hide mark
                unreadMarkAnimation()
            }
        }

        status = newStatus
    }

    func reset() {
        status = .read
        isEnabled = true
        unreadMark?.removeFromSuperview()
        unreadMark = nil
    }

    override var isHighlighted: Bool {
        didSet {
            self.unreadMark?.backgroundColor = isHighlighted ? unreadMarkColorHightlighted : unreadMarkColor
        }
    }
}
