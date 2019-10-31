//
//  TagDetectionUtil.swift
//  Stepic
//
//  Created by Alexander Karpov on 01.06.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

final class TagDetectionUtil {
    static let supportedHtmlTagsForLabel = ["b", "strong", "i", "em", "strike", "p", "br"]

    static func isWebViewSupportNeeded(_ htmlString: String) -> Bool {
        return self.detectLaTeX(htmlString) || self.detectUnsupportedTags(htmlString)
    }

    // POSSIBLY detects LaTeX in html string
    static func detectLaTeX(_ htmlString: String) -> Bool {
        return htmlString.filter({ $0 == "$" }).count >= 2
            || (htmlString.range(of: "\\[") != nil && htmlString.range(of: "\\]") != nil)
            || (htmlString.contains("math-tex"))
    }

    static func detectImage(_ htmlString: String) -> Bool {
        return HTMLParsingUtil.getImageSrcLinks(htmlString).count > 0
    }

    static func detectCode(_ htmlString: String) -> Bool {
        return HTMLParsingUtil.getCodeStrings(htmlString).count > 0
    }

    static func detectUnsupportedTags(_ htmlString: String) -> Bool {
        return HTMLParsingUtil.getAllHTMLTags(htmlString).filter { !supportedHtmlTagsForLabel.contains($0) }.count > 0
    }
}
