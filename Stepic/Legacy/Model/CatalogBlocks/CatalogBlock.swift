import Foundation
import SwiftyJSON

final class CatalogBlock: JSONSerializable, CustomStringConvertible {
    private static let defaultPosition = 1
    private static let defaultLanguage = "en"
    private static let defaultIsTitleVisible = true

    var id: Int = 0
    var position: Int = CatalogBlock.defaultPosition
    var title: String = ""
    var language: String = CatalogBlock.defaultLanguage
    var descriptionString: String = ""
    var kindString: String = ""
    var appearanceString: String = ""
    var isTitleVisible: Bool = CatalogBlock.defaultIsTitleVisible
    var content: [CatalogBlockContentItem] = []

    var kind: CatalogBlockKind? { CatalogBlockKind(rawValue: self.kindString) }
    var appearance: CatalogBlockAppearance? { CatalogBlockAppearance(rawValue: self.appearanceString) }

    var description: String {
        """
        CatalogBlock(id: \(self.id), \
        position: \(self.position), \
        title: \(self.title), \
        language: \(self.language), \
        description: \(self.descriptionString), \
        kind: \(self.kindString), \
        appearance: \(self.appearanceString), \
        isTitleVisible: \(self.isTitleVisible), \
        content: \(self.content))
        """
    }

    init(json: JSON) {
        self.update(json: json)
    }

    func update(json: JSON) {
        self.id = json[JSONKey.id.rawValue].intValue
        self.position = json[JSONKey.position.rawValue].int ?? Self.defaultPosition
        self.title = json[JSONKey.title.rawValue].stringValue
        self.language = json[JSONKey.language.rawValue].string ?? Self.defaultLanguage
        self.descriptionString = json[JSONKey.description.rawValue].stringValue
        self.kindString = json[JSONKey.kind.rawValue].stringValue
        self.appearanceString = json[JSONKey.appearance.rawValue].stringValue
        self.isTitleVisible = json[JSONKey.isTitleVisible.rawValue].bool ?? Self.defaultIsTitleVisible
        self.content = json[JSONKey.content.rawValue].arrayValue.compactMap {
            CatalogBlockContentItemParser.parse(json: $0, kind: self.kindString)
        }
    }

    enum JSONKey: String {
        case id
        case position
        case title
        case language
        case description
        case kind
        case appearance
        case isTitleVisible = "is_title_visible"
        case content
    }
}
