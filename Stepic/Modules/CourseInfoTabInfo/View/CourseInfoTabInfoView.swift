//
// CourseInfoTabInfoView.swift
// stepik-ios
//
//  Created by Ivan Magda on 11/1/18.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit
import Atributika

protocol CourseInfoTabInfoViewDelegate: class {
    func courseInfoTabInfoViewDidTapOnActionButton(
        _ courseInfoTabInfoView: CourseInfoTabInfoView
    )
}

extension CourseInfoTabInfoView {
    struct Appearance {
        let stackViewSpacing: CGFloat = 0

        let authorTitleLabelFont = UIFont.systemFont(ofSize: 14, weight: .light)
        let authorTitleHighlightColor = UIColor(hex: 0x0092E4)
        let authorTitleLabelInsets = UIEdgeInsets(top: 20, left: 47, bottom: 0, right: 47)
        let authorIconLeadingSpace: CGFloat = 20

        let actionButtonInsets = UIEdgeInsets(top: 32, left: 47, bottom: 32, right: 47)
        let actionButtonHeight: CGFloat = 47
        let actionButtonBackgroundColor = UIColor.stepicGreen
        let actionButtonFont = UIFont.systemFont(ofSize: 14)
        let actionButtonTextColor = UIColor.white
        let actionButtonCornerRadius: CGFloat = 7
    }
}

final class CourseInfoTabInfoView: UIView {
    weak var delegate: CourseInfoTabInfoViewDelegate?
    weak var videoViewDelegate: CourseInfoTabInfoIntroVideoBlockViewDelegate?

    let appearance: Appearance

    private lazy var scrollableStackView: ScrollableStackView = {
        let stackView = ScrollableStackView(frame: .zero, orientation: .vertical)
        stackView.showsVerticalScrollIndicator = false
        stackView.showsHorizontalScrollIndicator = false
        stackView.spacing = self.appearance.stackViewSpacing
        stackView.isScrollEnabled = false
        return stackView
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = self.appearance.actionButtonBackgroundColor
        button.titleLabel?.font = self.appearance.actionButtonFont
        button.tintColor = self.appearance.actionButtonTextColor
        button.layer.cornerRadius = self.appearance.actionButtonCornerRadius
        button.addTarget(
            self,
            action: #selector(self.actionButtonClicked(sender:)),
            for: .touchUpInside
        )
        return button
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIViewNoIntrinsicMetric,
            height: self.scrollableStackView.arrangedSubviews.last?.frame.maxY ?? 0
        )
    }

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance(),
        delegate: CourseInfoTabInfoViewDelegate? = nil,
        videoViewDelegate: CourseInfoTabInfoIntroVideoBlockViewDelegate? = nil
    ) {
        self.appearance = appearance
        self.delegate = delegate
        self.videoViewDelegate = videoViewDelegate
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }

    // MARK: Public API

    func showLoading() {
        self.hideLoading()

        self.skeleton.viewBuilder = {
            CourseInfoTabInfoSkeletonView()
        }
        self.skeleton.show()
    }

    func hideLoading() {
        self.skeleton.hide()
    }

    func configure(viewModel: CourseInfoTabInfoViewModel) {
        if !self.scrollableStackView.arrangedSubviews.isEmpty {
            self.scrollableStackView.removeAllArrangedViews()
        }

        self.addAuthorView(authorName: viewModel.author)
        self.addIntroVideoView(
            introVideoURL: viewModel.introVideoURL,
            introVideoThumbnailURL: viewModel.introVideoThumbnailURL
        )

        self.addTextBlockView(block: .about, message: viewModel.aboutText)
        self.addTextBlockView(block: .requirements, message: viewModel.requirementsText)
        self.addTextBlockView(block: .targetAudience, message: viewModel.targetAudienceText)

        self.addInstructorsView(instructors: viewModel.instructors)

        self.addTextBlockView(block: .timeToComplete, message: viewModel.timeToCompleteText)
        self.addTextBlockView(block: .language, message: viewModel.languageText)
        self.addTextBlockView(block: .certificate, message: viewModel.certificateText)
        self.addTextBlockView(block: .certificateDetails, message: viewModel.certificateDetailsText)

        self.addActionButton(title: viewModel.actionButtonTitle)

        // Redraw self cause geometry & sizes can be changed
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    @objc
    private func actionButtonClicked(sender: UIButton) {
        self.delegate?.courseInfoTabInfoViewDidTapOnActionButton(self)
    }

    // MARK: Private API

    private func addAuthorView(authorName: String) {
        if authorName.isEmpty {
            return
        }

        let authorView = CourseInfoTabInfoHeaderBlockView(
            appearance: .init(
                imageViewLeadingSpace: self.appearance.authorIconLeadingSpace,
                titleLabelFont: self.appearance.authorTitleLabelFont,
                titleLabelInsets: self.appearance.authorTitleLabelInsets
            )
        )

        let attributedTitle = "\(Block.author.title) <a>\(authorName)</a>".style(tags: [
            Style("a").foregroundColor(self.appearance.authorTitleHighlightColor)
        ]).attributedString

        authorView.icon = Block.author.icon
        authorView.attributedTitle = attributedTitle

        self.scrollableStackView.addArrangedView(authorView)
    }

    private func addIntroVideoView(introVideoURL: URL?, introVideoThumbnailURL: URL?) {
        if let introVideoURL = introVideoURL {
            let introVideoBlockView = CourseInfoTabInfoIntroVideoBlockView(
                delegate: self.videoViewDelegate
            )
            introVideoBlockView.thumbnailImageURL = introVideoThumbnailURL
            introVideoBlockView.videoURL = introVideoURL
            self.scrollableStackView.addArrangedView(introVideoBlockView)
        }
    }

    private func addTextBlockView(block: Block, message: String) {
        if message.isEmpty {
            return
        }

        let textBlockView = CourseInfoTabInfoTextBlockView()
        textBlockView.icon = block.icon
        textBlockView.title = block.title
        textBlockView.message = message

        self.scrollableStackView.addArrangedView(textBlockView)
    }

    private func addInstructorsView(instructors: [CourseInfoTabInfoInstructorViewModel]) {
        if instructors.isEmpty {
            return
        }

        let instructorsView = CourseInfoTabInfoInstructorsBlockView()
        instructorsView.configure(instructors: instructors)

        self.scrollableStackView.addArrangedView(instructorsView)
    }

    private func addActionButton(title: String) {
        self.actionButton.setTitle(title, for: .normal)

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(self.actionButton)

        self.scrollableStackView.addArrangedView(buttonContainer)
        self.actionButton.snp.makeConstraints { make in
            make.height.equalTo(self.appearance.actionButtonHeight)
            make.leading.top.trailing.bottom
                .equalToSuperview()
                .inset(self.appearance.actionButtonInsets)
        }
    }
}

// MARK: - CourseInfoTabInfoView: ProgrammaticallyInitializableViewProtocol -

extension CourseInfoTabInfoView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = .white
    }

    func addSubviews() {
        self.addSubview(self.scrollableStackView)
    }

    func makeConstraints() {
        self.scrollableStackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollableStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - CourseInfoTabInfoView (Block) -

extension CourseInfoTabInfoView {
    enum Block {
        case author
        case introVideo
        case about
        case requirements
        case targetAudience
        case instructors
        case timeToComplete
        case language
        case certificate
        case certificateDetails

        var icon: UIImage? {
            switch self {
            case .author:
                return UIImage(named: "course-info-instructor")
            case .introVideo:
                return nil
            case .about:
                return UIImage(named: "course-info-about")
            case .requirements:
                return UIImage(named: "course-info-requirements")
            case .targetAudience:
                return UIImage(named: "course-info-target-audience")
            case .instructors:
                return UIImage(named: "course-info-instructor")
            case .timeToComplete:
                return UIImage(named: "course-info-time-to-complete")
            case .language:
                return UIImage(named: "course-info-language")
            case .certificate:
                return UIImage(named: "course-info-certificate")
            case .certificateDetails:
                return UIImage(named: "course-info-certificate-details")
            }
        }

        var title: String {
            switch self {
            case .author:
                return NSLocalizedString("CourseInfoTitleAuthor", comment: "")
            case .introVideo:
                return ""
            case .about:
                return NSLocalizedString("CourseInfoTitleAbout", comment: "")
            case .requirements:
                return NSLocalizedString("CourseInfoTitleRequirements", comment: "")
            case .targetAudience:
                return NSLocalizedString("CourseInfoTitleTargetAudience", comment: "")
            case .instructors:
                return NSLocalizedString("CourseInfoTitleInstructors", comment: "")
            case .timeToComplete:
                return NSLocalizedString("CourseInfoTitleTimeToComplete", comment: "")
            case .language:
                return NSLocalizedString("CourseInfoTitleLanguage", comment: "")
            case .certificate:
                return NSLocalizedString("CourseInfoTitleCertificate", comment: "")
            case .certificateDetails:
                return NSLocalizedString("CourseInfoTitleCertificateDetails", comment: "")
            }
        }
    }
}
