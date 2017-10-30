//
//  HorizontalCoursesView.swift
//  Stepic
//
//  Created by Ostrenkiy on 25.10.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

class HorizontalCoursesView: NibInitializableView {

    @IBOutlet weak internal var titleLabel: StepikLabel!

    @IBOutlet weak internal var showAllButton: UIButton!

    @IBOutlet weak internal var courseCountLabel: StepikLabel!

    @IBOutlet weak internal var courseListContainerView: UIView!
    @IBOutlet weak var courseListContainerHeight: NSLayoutConstraint!

    let courseListHeight: CGFloat = 208
    let courseListPlaceholderHeight: CGFloat = 100

    private var showVerticalBlock: (() -> Void)?

    override var nibName: String {
        return "HorizontalCoursesView"
    }

    var courseCount: Int = 0 {
        didSet {
            courseCountLabel.text = courseCount == 0 || !shouldShowCount ? "" : "\(courseCount) курсов"
            showAllButton.isHidden = courseCount == 0
        }
    }

    var shouldShowCount: Bool = false

    @IBAction func showAllPressed(_ sender: Any) {
        showVerticalBlock?()
    }

    func setup(block: CourseListBlock, showVerticalBlock: @escaping () -> Void) {
        self.showVerticalBlock = showVerticalBlock

        block.horizontalController.changedPlaceholderVisibleBlock = {
            [weak self]
            visible in
            guard let strongSelf = self else {
                return
            }
            strongSelf.courseListContainerHeight.constant = visible ? strongSelf.courseListPlaceholderHeight : strongSelf.courseListHeight
        }
        titleLabel.text = block.title
        shouldShowCount = block.shouldShowCount
        courseCountLabel.colorMode = .gray
        courseCountLabel.isHidden = !shouldShowCount
        courseListContainerView.addSubview(block.horizontalController.view)
        block.horizontalController.view.align(toView: courseListContainerView)
        showAllButton.setTitleColor(UIColor.lightGray, for: .normal)
        switch block.colorMode {
        case .dark:
            view.backgroundColor = UIColor.mainDark
            titleLabel.colorMode = .light
        case .light:
            view.backgroundColor = UIColor.white
            titleLabel.colorMode = .dark
        }
    }

    override func setupSubviews() {

    }
}
