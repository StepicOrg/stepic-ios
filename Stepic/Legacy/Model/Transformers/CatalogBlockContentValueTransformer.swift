import Foundation

@available(iOS 12.0, *)
@objc(CatalogBlockContentValueTransformer)
final class CatalogBlockContentValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: CatalogBlockContentValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        [NSArray.self, CatalogBlockContentItem.self, NSDate.self, NSNumber.self, NSString.self]
    }

    static func register() {
        let transformer = CatalogBlockContentValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
