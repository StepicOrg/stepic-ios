import Foundation

@available(iOS 12.0, *)
@objc(DatasetValueTransformer)
final class DatasetValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: DatasetValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        [Dataset.self, FillBlanksComponent.self, NSArray.self, NSString.self]
    }

    static func register() {
        let transformer = DatasetValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
