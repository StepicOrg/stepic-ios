import Foundation

@available(iOS 12.0, *)
@objc(CatalogBlockContentValueTransformer)
final class CatalogBlockContentValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: CatalogBlockContentValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, CatalogBlockContentItem.self]
    }

    static func register() {
        let transformer = CatalogBlockContentValueTransformer()
        CatalogBlockContentValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
