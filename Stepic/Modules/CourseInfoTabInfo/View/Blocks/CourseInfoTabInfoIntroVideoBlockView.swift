//
// CourseInfoTabInfoIntroVideoBlockView.swift
// stepik-ios
//
// Created by Ivan Magda on 11/9/18.
// Copyright (c) 2018 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit

extension CourseInfoTabInfoIntroVideoBlockView {
    struct Appearance {
        let introVideoHeight: CGFloat = 203
        let insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
}

final class CourseInfoTabInfoIntroVideoBlockView: UIView {
    private let appearance: Appearance

    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "new-coursepics-python-xl"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CourseInfoTabInfoIntroVideoBlockView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = .white
    }

    func addSubviews() {
        self.addSubview(self.previewImageView)
    }

    func makeConstraints() {
        self.previewImageView.translatesAutoresizingMaskIntoConstraints = false
        self.previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(self.appearance.insets)
            make.height.equalTo(self.appearance.introVideoHeight)
        }
    }
}
