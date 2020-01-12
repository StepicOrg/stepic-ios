import Foundation
import PromiseKit

protocol NewSettingsInteractorProtocol {
    func doSettingsLoad(request: NewSettings.SettingsLoad.Request)
}

final class NewSettingsInteractor: NewSettingsInteractorProtocol {
    private let presenter: NewSettingsPresenterProtocol
    private let provider: NewSettingsProviderProtocol

    init(
        presenter: NewSettingsPresenterProtocol,
        provider: NewSettingsProviderProtocol
    ) {
        self.presenter = presenter
        self.provider = provider
    }

    func doSettingsLoad(request: NewSettings.SettingsLoad.Request) {
        self.presenter.presentSettings(response: .init())
    }

    enum Error: Swift.Error {
        case something
    }
}
