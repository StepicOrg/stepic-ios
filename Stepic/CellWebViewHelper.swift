//
//  CellWebViewHelper.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

class CellWebViewHelper: NSObject {

    fileprivate weak var webView: UIWebView?

    var mathJaxFinishedBlock : (() -> Void)?

    init(webView: UIWebView) {
        self.webView = webView
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = UIColor.clear
        self.webView?.isUserInteractionEnabled = false
        self.webView?.scrollView.backgroundColor = UIColor.clear
        self.webView?.scrollView.showsVerticalScrollIndicator = false
        self.webView?.scrollView.canCancelContentTouches = false
    }

    fileprivate func getContentHeight(_ webView: UIWebView) -> Int {
        return Int(webView.stringByEvaluatingJavaScript(from: "document.body.scrollHeight;") ?? "0") ?? 0
    }

    //Method sets text and returns the method which returns current cell height according to the webview content height
    func setTextWithTeX(_ text: String, color: UIColor = UIColor.mainText) {
        let processor = HTMLProcessor(html: text)
        let html = processor
            .injectDefault()
            .inject(script: .mathJaxCompletion)
            .inject(script: .textColor(color: color))
            .html

        webView?.delegate = self
        webView?.loadHTMLString(html, baseURL: URL(fileURLWithPath: Bundle.main.bundlePath))
    }

    deinit {
        print("deinit cell helper")
    }

    fileprivate func finishedMathJax() {
        mathJaxFinishedBlock?()
    }

}

extension CellWebViewHelper : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if request.url?.scheme == "mathjaxfinish" {
            finishedMathJax()
            return false
        }
        return true
    }
}
