//
//  CourseInfoTabSyllabusCellStatsView.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 21.11.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit
import Nuke

extension CourseInfoTabSyllabusCellStatsView {
    struct Appearance {
        let itemsSpacing: CGFloat = 20.0

        let itemTextFont = UIFont.systemFont(ofSize: 12, weight: .light)
        let itemTextColor = UIColor.mainDark

        let learnersImageColor = UIColor.mainDark
        let learnersImageSize = CGSize(width: 8.5, height: 11)
        let learnersSpacing: CGFloat = 5.0

        let likesImageColor = UIColor.mainDark
        let likesImageSize = CGSize(width: 10, height: 8.7)
        let likesSpacing: CGFloat = 5.0
    }
}

final class CourseInfoTabSyllabusCellStatsView: UIView {
    let appearance: Appearance

    private lazy var itemsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = self.appearance.itemsSpacing
        return stackView
    }()

    private lazy var learnersView: CourseWidgetStatsItemView = {
        var appearance = CourseWidgetStatsItemView.Appearance()
        appearance.iconSpacing = self.appearance.learnersSpacing
        appearance.imageViewSize = self.appearance.learnersImageSize
        appearance.imageTintColor = self.appearance.learnersImageColor
        appearance.textColor = self.appearance.itemTextColor
        appearance.font = self.appearance.itemTextFont
        let view = CourseWidgetStatsItemView(appearance: appearance)
        view.image = UIImage(named: "course-widget-user")!
            .withRenderingMode(.alwaysTemplate)
        return view
    }()

    private lazy var likesView: CourseWidgetStatsItemView = {
        var appearance = CourseWidgetStatsItemView.Appearance()
        appearance.iconSpacing = self.appearance.likesSpacing
        appearance.imageViewSize = self.appearance.likesImageSize
        appearance.imageTintColor = self.appearance.likesImageColor
        appearance.textColor = self.appearance.itemTextColor
        appearance.font = self.appearance.itemTextFont
        let view = CourseWidgetStatsItemView(appearance: appearance)
        view.image = UIImage(named: "course-info-lesson-like")!
            .withRenderingMode(.alwaysTemplate)
        return view
    }()

    private lazy var progressView: CourseWidgetStatsItemView = {
        var appearance = CourseWidgetStatsItemView.Appearance()
        // There is no icon in this view now
        appearance.iconSpacing = 0
        appearance.imageViewSize = .zero
        appearance.textColor = self.appearance.itemTextColor
        appearance.font = self.appearance.itemTextFont
        let view = CourseWidgetStatsItemView(appearance: appearance)
        return view
    }()

    var learnersLabelText: String? {
        didSet {
            self.learnersView.isHidden = self.learnersLabelText == nil
            self.learnersView.text = self.learnersLabelText
        }
    }

    var likesCount: Int? {
        didSet {
            self.likesView.isHidden = self.likesCount == nil

            if let likesCount = self.likesCount {
                self.likesView.image = likesCount >= 0
                    ? UIImage(named: "course-info-lesson-like")!.withRenderingMode(.alwaysTemplate)
                    : UIImage(named: "course-info-lesson-dislike")!.withRenderingMode(.alwaysTemplate)
                self.likesView.text = "\(likesCount)"
            }
        }
    }

    var progressLabelText: String? {
        didSet {
            self.progressView.isHidden = self.progressLabelText == nil
            self.progressView.text = self.progressLabelText
        }
    }

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CourseInfoTabSyllabusCellStatsView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.likesView.isHidden = false
        self.progressView.isHidden = false
    }

    func addSubviews() {
        self.addSubview(self.itemsStackView)
        self.itemsStackView.addArrangedSubview(self.learnersView)
        self.itemsStackView.addArrangedSubview(self.likesView)
        self.itemsStackView.addArrangedSubview(self.progressView)
    }

    func makeConstraints() {
        self.itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        self.itemsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
