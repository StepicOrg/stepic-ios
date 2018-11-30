//
//  CourseInfoHeaderView.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 01/11/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit

extension CourseInfoHeaderView {
    struct Appearance {
        let actionButtonInsets = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
        let actionButtonHeight: CGFloat = 42.0
        let actionButtonWidthRatio: CGFloat = 0.55

        let coverImageViewSize = CGSize(width: 36, height: 36)
        let coverImageViewCornerRadius: CGFloat = 3
        let coverImageViewInsets = UIEdgeInsets(top: 18, left: 30, bottom: 14, right: 10)

        let titleLabelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let titleLabelColor = UIColor.white
        let titleLabelInsets = UIEdgeInsets(top: 18, left: 10, bottom: 14, right: 30)

        let marksStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 18, right: 0)
        let marksStackViewSpacing: CGFloat = 10.0

        let statsViewHeight: CGFloat = 17.0

        let verifiedTextColor = UIColor.white
        let verifiedImageSize = CGSize(width: 11, height: 11)
        let verifiedSpacing: CGFloat = 4.0
        let verifiedTextFont = UIFont.systemFont(ofSize: 12, weight: .light)
    }
}

final class CourseInfoHeaderView: UIView {
    let appearance: Appearance

    private lazy var backgroundView: CourseInfoBlurredBackgroundView = {
        let view = CourseInfoBlurredBackgroundView()
        // To prevent tap handling
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var actionButton: ContinueActionButton = {
        let button = ContinueActionButton(mode: .callToAction)
        button.setTitle(NSLocalizedString("WidgetButtonJoin", comment: ""), for: .normal)
        return button
    }()

    private lazy var coverImageView: CourseCoverImageView = {
        let view = CourseCoverImageView()
        view.clipsToBounds = true
        view.layer.cornerRadius = self.appearance.coverImageViewCornerRadius
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = self.appearance.titleLabelFont
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = self.appearance.titleLabelColor
        return label
    }()

    private lazy var verifiedSignView: CourseWidgetStatsItemView = {
        var appearance = CourseWidgetStatsItemView.Appearance()
        appearance.iconSpacing = self.appearance.verifiedSpacing
        appearance.imageViewSize = self.appearance.verifiedImageSize
        appearance.textColor = self.appearance.verifiedTextColor
        appearance.font = self.appearance.verifiedTextFont
        let view = CourseWidgetStatsItemView(appearance: appearance)
        view.image = UIImage(named: "course-info-verified")!
        view.text = NSLocalizedString("CourseMeetsRecommendations", comment: "")
        return view
    }()

    // Stack view for stat items (learners, rating, ...) and "verified" mark
    private lazy var marksStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = self.appearance.marksStackViewSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private lazy var statsView = CourseInfoStatsView()

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: CourseInfoHeaderViewModel) {
        self.loadImage(url: viewModel.coverImageURL)

        self.titleLabel.text = viewModel.title

        self.statsView.learnersLabelText = viewModel.learnersLabelText
        self.statsView.rating = viewModel.rating
        self.statsView.progress = viewModel.progress

        self.verifiedSignView.isHidden = !viewModel.isVerified
    }

    private func loadImage(url: URL?) {
        self.backgroundView.loadImage(url: url)
        self.coverImageView.loadImage(url: url)
    }
}

extension CourseInfoHeaderView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.marksStackView.addArrangedSubview(self.statsView)
        self.marksStackView.addArrangedSubview(self.verifiedSignView)

        self.addSubview(self.backgroundView)
        self.addSubview(self.actionButton)
        self.addSubview(self.coverImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.marksStackView)
    }

    func makeConstraints() {
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.coverImageView.translatesAutoresizingMaskIntoConstraints = false
        self.coverImageView.snp.makeConstraints { make in
            make.size.equalTo(self.appearance.coverImageViewSize)
            make.bottom.equalToSuperview().offset(-self.appearance.titleLabelInsets.bottom)
            make.leading.equalToSuperview().offset(self.appearance.coverImageViewInsets.left)
        }

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualToSuperview().offset(-self.appearance.titleLabelInsets.bottom)
            make.trailing.equalToSuperview().offset(-self.appearance.titleLabelInsets.right)
            make.leading
                .equalTo(self.coverImageView.snp.trailing)
                .offset(self.appearance.titleLabelInsets.left)
            make.top.equalTo(self.coverImageView.snp.top)
        }

        self.statsView.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.statsViewHeight)
        }

        self.marksStackView.translatesAutoresizingMaskIntoConstraints = false
        self.marksStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom
                .equalTo(self.coverImageView.snp.top)
                .offset(-self.appearance.marksStackViewInsets.bottom)
        }

        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.actionButton.snp.makeConstraints { make in
            make.bottom
                .equalTo(self.statsView.snp.top)
                .offset(-self.appearance.actionButtonInsets.bottom)
            make.centerX.equalToSuperview()
            make.height.equalTo(self.appearance.actionButtonHeight)
            make.width
                .equalTo(self.snp.width)
                .multipliedBy(self.appearance.actionButtonWidthRatio)
        }
    }
}
