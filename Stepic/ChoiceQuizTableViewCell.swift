//
//  ChoiceQuizTableViewCell.swift
//  Stepic
//
//  Created by Alexander Karpov on 06.06.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import BEMCheckBox
import SnapKit
import UIKit

final class ChoiceQuizTableViewCell: UITableViewCell {
    @IBOutlet weak var textContainerView: UIView!
    @IBOutlet weak var checkBox: BEMCheckBox!

    var optionLabel: StepikLabel?
    var optionWebView: FullHeightWebView?

    var webViewHelper: CellWebViewHelper?

    private func initLabel() {
        guard optionLabel == nil else { return }
        optionLabel = StepikLabel()
        guard let optionLabel = optionLabel else { return }
        optionLabel.numberOfLines = 0
        optionLabel.font = UIFont(name: "ArialMT", size: 16)
        optionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        optionLabel.baselineAdjustment = UIBaselineAdjustment.alignBaselines
        optionLabel.textAlignment = NSTextAlignment.natural
        optionLabel.backgroundColor = UIColor.clear
        textContainerView.addSubview(optionLabel)
        optionLabel.snp.makeConstraints { make -> Void in
            make.top.bottom.equalTo(textContainerView)
            make.leading.equalTo(textContainerView).offset(8)
            make.trailing.equalTo(textContainerView).offset(-8)
        }
        optionLabel.isHidden = true
    }

    private func initWebView() {
        guard optionWebView == nil else { return }
        optionWebView = FullHeightWebView()
        guard let optionWebView = optionWebView else { return }
        textContainerView.addSubview(optionWebView)
        optionWebView.snp.makeConstraints { $0.edges.equalTo(textContainerView) }
        webViewHelper = CellWebViewHelper(webView: optionWebView, fontSize: StepFontSizeService().globalStepFontSize)
        optionWebView.isHidden = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        checkBox.onAnimationType = .fill
        checkBox.animationDuration = 0.3
        contentView.backgroundColor = UIColor.clear
        checkBox.onTintColor = UIColor.mainDark
        checkBox.onFillColor = UIColor.mainDark
        checkBox.tintColor = UIColor.mainDark
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        optionWebView?.isHidden = true
        optionLabel?.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    static func getHeightForText(text: String, width: CGFloat) -> CGFloat {
        let labelHeight = StepikLabel.heightForLabelWithText(
            text, lines: 0, fontName: "ArialMT", fontSize: 16, width: width - 68, html: true
        )

        return max(27, labelHeight) + 17
    }
}

extension ChoiceQuizTableViewCell {
    //All optimization logic is now encapsulated here
    func setHTMLText(_ text: String, width: CGFloat, finishedBlock: @escaping (CGFloat) -> Void) {
        if TagDetectionUtil.isWebViewSupportNeeded(text) {
            initWebView()
            optionWebView?.isHidden = false
            webViewHelper?.mathJaxFinishedBlock = {
                [weak self] in
                self?.layoutIfNeeded()
                if let webView = self?.optionWebView {
                    webView.invalidateIntrinsicContentSize()
                    finishedBlock(17 + webView.contentHeight)
                }
            }
            webViewHelper?.setTextWithTeX(text)
        } else {
            initLabel()
            optionLabel?.setTextWithHTMLString(text)
            optionLabel?.isHidden = false
            let height = ChoiceQuizTableViewCell.getHeightForText(text: text, width: width)
            finishedBlock(height)
        }
    }
}
