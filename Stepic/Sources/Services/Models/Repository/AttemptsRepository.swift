import Foundation
import PromiseKit

protocol AttemptsRepositoryProtocol: AnyObject {
    func fetch(ids: [Attempt.IdType], blockName: String) -> Promise<[Attempt]>
    func fetch(stepID: Step.IdType, userID: User.IdType, blockName: String) -> Promise<([Attempt], Meta)>
    func create(stepID: Step.IdType, blockName: String) -> Promise<Attempt>
}

final class AttemptsRepository: AttemptsRepositoryProtocol {
    private let attemptsNetworkService: AttemptsNetworkServiceProtocol
    private let attemptsPersistenceService: AttemptsPersistenceServiceProtocol

    init(
        attemptsNetworkService: AttemptsNetworkServiceProtocol,
        attemptsPersistenceService: AttemptsPersistenceServiceProtocol
    ) {
        self.attemptsNetworkService = attemptsNetworkService
        self.attemptsPersistenceService = attemptsPersistenceService
    }

    func fetch(ids: [Attempt.IdType], blockName: String) -> Promise<[Attempt]> {
        let persistenceServicePromise = Guarantee(self.attemptsPersistenceService.fetch(ids: ids), fallback: nil)
        let networkServicePromise = Guarantee(
            self.attemptsNetworkService.fetch(ids: ids, blockName: blockName),
            fallback: nil
        )

        return Promise { seal in
            when(
                fulfilled: persistenceServicePromise,
                networkServicePromise
            ).done { cachedAttempts, remoteAttemptsOrNil in
                if let remoteAttempts = remoteAttemptsOrNil {
                    self.attemptsPersistenceService.save(attempts: remoteAttempts).done {
                        seal.fulfill(remoteAttempts)
                    }
                } else if let cachedAttempts = cachedAttempts {
                    let plainAttempts = cachedAttempts.map { $0.plainObject }
                    seal.fulfill(plainAttempts)
                } else {
                    seal.fulfill([])
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    func fetch(stepID: Step.IdType, userID: User.IdType, blockName: String) -> Promise<([Attempt], Meta)> {
        let persistenceServicePromise = Guarantee(
            self.attemptsPersistenceService.fetchStepAttempts(stepID: stepID),
            fallback: nil
        )
        let networkServicePromise = Guarantee(
            self.attemptsNetworkService.fetch(stepID: stepID, userID: userID, blockName: blockName),
            fallback: nil
        )

        return Promise { seal in
            when(
                fulfilled: persistenceServicePromise,
                networkServicePromise
            ).done { cachedAttempts, remoteFetchResult in
                if let remoteFetchResult = remoteFetchResult {
                    self.attemptsPersistenceService
                        .save(attempts: remoteFetchResult.0)
                        .done { seal.fulfill(remoteFetchResult) }
                } else if let cachedAttempts = cachedAttempts {
                    let plainAttempts = cachedAttempts.map { $0.plainObject }
                    seal.fulfill((plainAttempts, Meta.oneAndOnlyPage))
                } else {
                    seal.fulfill(([], Meta.oneAndOnlyPage))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    func create(stepID: Step.IdType, blockName: String) -> Promise<Attempt> {
        self.attemptsNetworkService
            .create(stepID: stepID, blockName: blockName)
            .then { attempt in
                self.attemptsPersistenceService
                    .save(attempts: [attempt])
                    .map { attempt }
            }
    }
}
