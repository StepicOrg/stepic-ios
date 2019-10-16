//
//  SwitchMenuBlockTableViewCell.swift
//  Stepic
//
//  Created by Ostrenkiy on 30.08.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

final class SwitchMenuBlockTableViewCell: MenuBlockTableViewCell {
    @IBOutlet weak var titleLabel: StepikLabel!
    @IBOutlet weak var blockSwitch: UISwitch!

    var block: SwitchMenuBlock?

    func initWithBlock(block: SwitchMenuBlock) {
        super.initWithBlock(block: block)
        titleLabel.text = block.title
        titleLabel.textColor = block.titleColor
        blockSwitch.isOn = block.isOn
        self.block = block
    }

    @IBAction func switchChanged(_ sender: Any) {
        guard let block = block else {
            return
        }
        block.onSwitch?(blockSwitch.isOn)
        separator.isHidden = !block.hasSeparatorOnBottom
    }
}
