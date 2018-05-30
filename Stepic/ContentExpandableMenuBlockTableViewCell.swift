//
//  ContentExpandableMenuBlockTableViewCell.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 27.05.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

class ContentExpandableMenuBlockTableViewCell: MenuBlockTableViewCell {
    @IBOutlet weak var titleLabel: StepikLabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var arrowButton: UIButton!

    var bottomTitleConstraint: NSLayoutConstraint?

    var block: ContentExpandableMenuBlock?
    var updateTableHeightBlock: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func initWithBlock(block: MenuBlock) {
        super.initWithBlock(block: block)
        titleLabel.text = block.title

        if let block = block as? ContentExpandableMenuBlock {
            self.block = block
            if let contentView = block.contentView {
                container.addSubview(contentView)
                contentView.alignTop("0", leading: "0", bottom: "0", trailing: "0", toView: container)
                layoutIfNeeded()
            }

            if block.isExpanded {
                expand()
            } else {
                shrink()
            }
        }
    }

    @IBAction func arrowButtonPressed(_ sender: UIButton) {
        expandPressed()
    }

    func expandPressed() {
        guard let block = block else {
            return
        }

        block.onExpanded?(!block.isExpanded)
        if block.isExpanded {
            expand()
        } else {
            shrink()
        }
        layoutIfNeeded()
        updateTableHeightBlock?()
    }

    func expand() {
        bottomTitleConstraint?.isActive = false
        container.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.arrowButton.transform = CGAffineTransform.identity
        }
    }

    func shrink() {
        container.isHidden = true
        if bottomTitleConstraint == nil {
            bottomTitleConstraint = titleLabel.alignBottomEdge(withView: self.contentView, predicate: "-26")
        } else {
            bottomTitleConstraint?.isActive = true
        }
        UIView.animate(withDuration: 0.3) {
            self.arrowButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }
    }

}
