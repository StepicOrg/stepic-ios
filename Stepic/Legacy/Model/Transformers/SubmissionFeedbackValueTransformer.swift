import Foundation

@available(iOS 12.0, *)
@objc(SubmissionFeedbackValueTransformer)
final class SubmissionFeedbackValueTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: SubmissionFeedbackValueTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        [SubmissionFeedback.self, NSArray.self, NSString.self]
    }

    static func register() {
        let transformer = SubmissionFeedbackValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
