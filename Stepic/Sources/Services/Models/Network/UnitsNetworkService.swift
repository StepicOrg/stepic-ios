import Foundation
import PromiseKit

protocol UnitsNetworkServiceProtocol: AnyObject {
    func fetch(ids: [Unit.IdType]) -> Promise<[Unit]>
    func fetch(id: Unit.IdType) -> Promise<Unit?>
}

final class UnitsNetworkService: UnitsNetworkServiceProtocol {
    private let unitsAPI: UnitsAPI

    init(unitsAPI: UnitsAPI) {
        self.unitsAPI = unitsAPI
    }

    func fetch(ids: [Unit.IdType]) -> Promise<[Unit]> {
        Promise { seal in
            self.unitsAPI.retrieve(ids: ids).done { units in
                let units = units.reordered(order: ids, transform: { $0.id })
                seal.fulfill(units)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetch(id: Unit.IdType) -> Promise<Unit?> {
        self.fetch(ids: [id]).then { result -> Promise<Unit?> in
            Promise.value(result.first)
        }
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
