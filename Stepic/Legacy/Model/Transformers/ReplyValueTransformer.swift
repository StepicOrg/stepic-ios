import Foundation

@available(iOS 12.0, *)
@objc(ReplyValueTransformer)
final class ReplyValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: ReplyValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        [Reply.self, NSArray.self, TableReplyChoice.self, TableReplyChoice.Column.self, NSNumber.self, NSString.self]
    }

    static func register() {
        let transformer = ReplyValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
