//
//  FullHeightWebView.swift
//  Stepic
//
//  Created by Ostrenkiy on 28.07.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

final class FullHeightWebView: UIWebView {
    var contentHeight: CGFloat {
        return CGFloat(Float(self.stringByEvaluatingJavaScript(from: "document.body.scrollHeight;") ?? "0") ?? 0)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.contentHeight)
    }
}
