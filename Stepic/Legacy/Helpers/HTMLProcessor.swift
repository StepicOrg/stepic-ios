//
//  HTMLProcessor.swift
//  Stepic
//
//  Created by Ostrenkiy on 09.07.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use ContentProcessor instead")
final class HTMLProcessor {
    private var htmlString: String
    private var headInjections = ""
    private var bodyInjectionsHead = ""
    private var bodyInjectionsTail = ""

    var html: String {
        "<html><head>\(headInjections)</head><body>\(bodyInjectionsHead)\(addStepikURLWhereNeeded(body: htmlString))\(bodyInjectionsTail)</body></html>"
    }

    enum SupportedScripts {
        case metaViewport
        case localTex
        case clickableImages
        case styles
        case kotlinRunnableSamples
        case audio
        case textColor(color: UIColor)
        case mathJaxCompletion
        case highlightJS
        case customHead(head: String)
        case customBody(body: String)
        case fontSize(stepFontSize: StepFontSize)

        var headInjectionString: String {
            switch self {
            case .metaViewport:
                return Scripts.metaViewport
            case .localTex:
                return Scripts.localMathJax
            case .clickableImages:
                return Scripts.clickableImages
            case .styles:
                return Scripts.styles
            case .kotlinRunnableSamples:
                return Scripts.localKotlinPlayground
            case .audio:
                return Scripts.audioTagWrapper
            case .mathJaxCompletion:
                return Scripts.mathJaxFinished
            case .highlightJS:
                return Scripts.highlightJS
            case .customHead(let customHead):
                return customHead
            default:
                return ""
            }
        }

        var bodyInjectionString: String {
            switch self {
            case .audio:
                return Scripts.audioTagWrapperInit
            case .textColor(let color):
                return TextColorInjection(lightColor: color, darkColor: color).bodyHeadScript
            case .fontSize(let stepFontSize):
                return FontSizeInjection(stepFontSize: stepFontSize).bodyHeadScript
            case .customBody(let customBody):
                return customBody
            default:
                return ""
            }
        }

        var bodyInjectPosition: BodyInjectPosition {
            switch self {
            case .audio:
                return .tail
            default:
                return .head
            }
        }

        enum BodyInjectPosition {
            case head
            case tail
        }
    }

    init(html: String) {
        self.htmlString = html
    }

    func injectDefault() -> HTMLProcessor {
        self
            .inject(script: .audio)
            .inject(script: .clickableImages)
            .inject(script: .localTex)
            .inject(script: .styles)
            .inject(script: .metaViewport)
            .inject(script: .kotlinRunnableSamples)
            .inject(script: .highlightJS)
            .inject(script: .textColor(color: UIColor.stepikPrimaryText))
    }

    func inject(script: SupportedScripts, inTail: Bool = false) -> HTMLProcessor {
        func injectInHTML(script: SupportedScripts) {
            self.headInjections += script.headInjectionString

            if script.bodyInjectPosition == .head {
                self.bodyInjectionsHead += script.bodyInjectionString
            } else {
                self.bodyInjectionsTail = script.bodyInjectionString + self.bodyInjectionsTail
            }
        }

        switch script {
        case .kotlinRunnableSamples:
            if htmlString.contains("<kotlin-runnable") {
                injectInHTML(script: script)
            }
        case .audio:
            if htmlString.contains("<audio") {
                injectInHTML(script: script)
            }
        case .highlightJS:
            if htmlString.contains("<code") {
                injectInHTML(script: script)
            }
        default:
            injectInHTML(script: script)
        }
        return self
    }

    private func addStepikURLWhereNeeded(body: String) -> String {
        var body = body
        body = fixProtocolRelativeURLs(html: body)

        var links = HTMLParsingUtil.getAllLinksWithText(body).map { $0.link }
        links += HTMLParsingUtil.getImageSrcLinks(body)
        var linkMap = [String: String]()

        for link in links {
            if link.first == Character("/") {
                linkMap[link] = HTMLProcessor.addStepikURLIfNeeded(url: link)
            }
        }

        var newBody = body
        for (key, val) in linkMap {
            newBody = newBody.replacingOccurrences(of: "\"\(key)", with: "\"\(val)")
        }

        return newBody
    }

    static func addStepikURLIfNeeded(url: String) -> String {
        if url.first == Character("/") {
            return "\(StepikApplicationsInfo.stepikURL)\(url)"
        } else {
            return url
        }
    }

    private func fixProtocolRelativeURLs(html: String) -> String {
        html.replacingOccurrences(of: "src=\"//", with: "src=\"http://")
    }
}
