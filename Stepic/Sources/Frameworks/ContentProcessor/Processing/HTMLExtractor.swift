import Foundation
import Kanna

protocol HTMLExtractorProtocol: AnyObject {
    static func extractAllTagsAttribute(tag: String, attribute: String, from text: String) -> [String]
    static func extractAllTagsContent(tag: String, from text: String) -> [String]
    static func extractAllTags(tag: String, from text: String) -> [String]
}

final class HTMLExtractor: HTMLExtractorProtocol {
    private static func makeDocumentDOM(from text: String) -> HTMLDocument? {
        let trimmedText = text.trimmed()

        if trimmedText.isEmpty {
            return nil
        }

        return try? Kanna.HTML(html: trimmedText, encoding: String.Encoding.utf8)
    }

    static func extractAllTagsAttribute(tag: String, attribute: String, from text: String) -> [String] {
        guard let documentDOM = HTMLExtractor.makeDocumentDOM(from: text) else {
            return []
        }

        return documentDOM.css(tag).compactMap { $0[attribute] }
    }

    static func extractAllTagsContent(tag: String, from text: String) -> [String] {
        guard let documentDOM = HTMLExtractor.makeDocumentDOM(from: text) else {
            return []
        }

        return documentDOM.css(tag).compactMap { $0.text }
    }

    static func extractAllTags(tag: String, from text: String) -> [String] {
        guard let documentDOM = HTMLExtractor.makeDocumentDOM(from: text) else {
            return []
        }

        return documentDOM.css(tag).compactMap { $0.toHTML }
    }
}
