//
//  MainCourseInfoCell.swift
//  StepikTV
//
//  Created by Александр Пономарев on 27.10.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

class MainCourseInfoSectionCell: UICollectionViewCell, CourseInfoSectionViewProtocol {
    static var nibName: String { return "MainCourseInfoSectionCell" }
    static var reuseIdentifier: String { return "MainCourseInfoSectionCell" }

    static func getHeightForCell(section: CourseInfoSection, width: CGFloat) -> CGFloat {
        // Hardcoding cell's height according to the income content

        guard case let .main(host: host, descr: descr, imageURL: _, trailerAction: _, subscriptionAction: _, selectionAction: _, enrolled: _) = section.contentType else {
            return 35.0
        }

        let titleHeight = max(69.0, UILabel.heightForLabelWithText(section.title, lines: 0, font: UIFont.systemFont(ofSize: 57, weight: .medium), width: width - 1000, alignment: .left))

        let hostsHeight = max(46.0, UILabel.heightForLabelWithText(host, lines: 0, font: UIFont.systemFont(ofSize: 38, weight: .medium), width: width - 1000, alignment: .left))

        var contentHeight = UILabel.heightForLabelWithText(descr, lines: 0, font: UIFont.systemFont(ofSize: 29, weight: .regular), width: width - 1000, alignment: .left)
            contentHeight = contentHeight > 350.0 ? 350.0 : contentHeight

        return (titleHeight + hostsHeight + contentHeight + 300.0)
    }

    @IBOutlet var title: UILabel!
    @IBOutlet var hosts: UILabel!
    @IBOutlet var descr: TVFocusableText!
    @IBOutlet var leftIconButton: TVIconButton!
    @IBOutlet var rightIconButton: TVIconButton!
    @IBOutlet var imageView: UIImageView!

    private let introTitle = NSLocalizedString("Intro", comment: "")
    private let subscribeTitle = NSLocalizedString("Subscribe", comment: "")
    private let subscribedTitle = NSLocalizedString("Leave", comment: "")

    override func awakeFromNib() {
        super.awakeFromNib()

        descr.setupStyle(defaultTextColor: UIColor.black, focusedTextColor: UIColor.white, substrateViewColor: UIColor(hex: 0x80c972).withAlphaComponent(0.8))
    }

    func setup(with section: CourseInfoSection) {
        title.text = section.title

        switch section.contentType {
        case let .main(host: host, descr: descr, imageURL: imageURL, trailerAction: trailerAction, subscriptionAction: subscriptionAction, selectionAction: selectionAction, enrolled: enrolled):
            self.hosts.text = host
            self.descr.setTextWithHTMLString(descr)
            self.descr.pressAction = selectionAction
            self.imageView.setImageWithURL(url: imageURL, placeholder: #imageLiteral(resourceName: "placeholder"))
            self.setIntro(action: trailerAction)
            self.setSubscribed(enrolled: enrolled, action: subscriptionAction)
            self.setAuthorized(status: section.isAuthorized)
        default:
            fatalError("Sections data and view dependencies fails")
        }
    }

    func setIntro(action: (() -> Void)? = nil) {
        self.leftIconButton.configure(with: #imageLiteral(resourceName: "intro_icon"), introTitle)
        self.leftIconButton.pressAction = action

        self.leftIconButton.isEnabled = !(action == nil)
    }

    func setSubscribed(enrolled: Bool, action: @escaping () -> Void) {
        let title = enrolled ? subscribedTitle : subscribeTitle
        let image = enrolled ? #imageLiteral(resourceName: "unsubscribe_icon") : #imageLiteral(resourceName: "subscribe_icon")
        self.rightIconButton.configure(with: image, title)
        self.rightIconButton.pressAction = action
    }

    func setAuthorized(status: Bool) {
        self.rightIconButton.isEnabled = status
    }

}
