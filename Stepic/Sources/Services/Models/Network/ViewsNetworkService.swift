import Foundation
import PromiseKit

protocol ViewsNetworkServiceProtocol: AnyObject {
    func create(step: Step.IdType, assignment: Assignment.IdType?) -> Promise<Void>
}

final class ViewsNetworkService: ViewsNetworkServiceProtocol {
    private let viewsAPI: ViewsAPI

    init(viewsAPI: ViewsAPI) {
        self.viewsAPI = viewsAPI
    }

    func create(step: Step.IdType, assignment: Assignment.IdType?) -> Promise<Void> {
        Promise { seal in
            self.viewsAPI.create(step: step, assignment: assignment).done {
                seal.fulfill(())
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
