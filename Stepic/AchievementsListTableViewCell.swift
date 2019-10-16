//
//  AchievementsListTableViewCell.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 13.06.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

final class AchievementsListTableViewCell: UITableViewCell {
    @IBOutlet weak var badgeContainer: UIView!
    @IBOutlet weak var achievementName: UILabel!
    @IBOutlet weak var achievementDescription: UILabel!

    private var badgeView: AchievementBadgeView?

    static let reuseId = "AchievementsListTableViewCell"

    func update(with viewData: AchievementViewData) {
        achievementName.text = viewData.title
        achievementDescription.text = viewData.description

        if badgeView == nil {
            let badgeView: AchievementBadgeView = AchievementBadgeView.fromNib()
            badgeView.translatesAutoresizingMaskIntoConstraints = false
            badgeContainer.addSubview(badgeView)
            badgeView.snp.makeConstraints { $0.edges.equalTo(badgeContainer) }
            self.badgeView = badgeView
        }

        badgeView?.data = viewData
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
