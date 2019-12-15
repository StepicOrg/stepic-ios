import Foundation

protocol TooltipStorageManagerProtocol: AnyObject {
    var didShowOnHomeContinueLearning: Bool { get set }
    var didShowOnPersonalDeadlinesButton: Bool { get set }
}

@available(*, deprecated, message: "Code for backward compatibility")
final class TooltipStorageManager: TooltipStorageManagerProtocol {
    var didShowOnHomeContinueLearning: Bool {
        get {
            return TooltipDefaultsManager.shared.didShowOnHomeContinueLearning
        }
        set {
            TooltipDefaultsManager.shared.didShowOnHomeContinueLearning = newValue
        }
    }

    var didShowOnPersonalDeadlinesButton: Bool {
        get {
            return TooltipDefaultsManager.shared.didShowOnPersonalDeadlinesButton
        }
        set {
            TooltipDefaultsManager.shared.didShowOnPersonalDeadlinesButton = newValue
        }
    }

    init() { }
}
