import Foundation
import PromiseKit

protocol SubmissionsProviderProtocol {
    func fetchStep(id: Step.IdType) -> Promise<Step?>
    func fetchSteps(ids: [Step.IdType]) -> Promise<[Step]>

    func fetchSubmissions(
        stepID: Step.IdType,
        filterQuery: SubmissionsFilterQuery,
        page: Int
    ) -> Promise<([Submission], Meta)>

    func fetchAttempts(ids: [Attempt.IdType], stepID: Step.IdType) -> Promise<[Attempt]>

    func fetchReviewSessions(ids: [Int], stepID: Step.IdType) -> Promise<[ReviewSessionDataPlainObject]>
    func fetchReviewSession(
        userID: User.IdType,
        instructionID: Int,
        stepID: Step.IdType
    ) -> Promise<ReviewSessionDataPlainObject?>

    func fetchInstruction(id: Int) -> Promise<InstructionDataPlainObject?>

    func fetchUsers(ids: [User.IdType]) -> Promise<[User]>
    func fetchCurrentUser() -> Guarantee<User?>
    func getCurrentUserID() -> User.IdType?
}

final class SubmissionsProvider: SubmissionsProviderProtocol {
    private let submissionsNetworkService: SubmissionsNetworkServiceProtocol
    private let attemptsNetworkService: AttemptsNetworkServiceProtocol
    private let reviewSessionsNetworkService: ReviewSessionsNetworkServiceProtocol
    private let instructionsNetworkService: InstructionsNetworkServiceProtocol

    private let usersNetworkService: UsersNetworkServiceProtocol
    private let usersPersistenceService: UsersPersistenceServiceProtocol
    private let userAccountService: UserAccountServiceProtocol

    private let stepsNetworkService: StepsNetworkServiceProtocol
    private let stepsPersistenceService: StepsPersistenceServiceProtocol

    init(
        submissionsNetworkService: SubmissionsNetworkServiceProtocol,
        attemptsNetworkService: AttemptsNetworkServiceProtocol,
        reviewSessionsNetworkService: ReviewSessionsNetworkServiceProtocol,
        instructionsNetworkService: InstructionsNetworkServiceProtocol,
        usersNetworkService: UsersNetworkServiceProtocol,
        usersPersistenceService: UsersPersistenceServiceProtocol,
        userAccountService: UserAccountServiceProtocol,
        stepsNetworkService: StepsNetworkServiceProtocol,
        stepsPersistenceService: StepsPersistenceServiceProtocol
    ) {
        self.submissionsNetworkService = submissionsNetworkService
        self.attemptsNetworkService = attemptsNetworkService
        self.reviewSessionsNetworkService = reviewSessionsNetworkService
        self.instructionsNetworkService = instructionsNetworkService
        self.usersNetworkService = usersNetworkService
        self.usersPersistenceService = usersPersistenceService
        self.userAccountService = userAccountService
        self.stepsNetworkService = stepsNetworkService
        self.stepsPersistenceService = stepsPersistenceService
    }

    // MARK: Protocol Conforming

    func fetchStep(id: Step.IdType) -> Promise<Step?> {
        Promise { seal in
            firstly {
                self.stepsPersistenceService.fetch(ids: [id])
            }.then { cachedSteps -> Promise<[Step]> in
                if !cachedSteps.isEmpty {
                    return .value(cachedSteps)
                }
                return self.stepsNetworkService.fetch(ids: [id])
            }.done { steps in
                seal.fulfill(steps.first)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchSteps(ids: [Step.IdType]) -> Promise<[Step]> {
        Promise { seal in
            let uniqueIDs = Set(ids)
            let uniqueIDsArray = Array(uniqueIDs).reordered(order: ids, transform: { $0 })

            self.stepsPersistenceService.fetch(ids: uniqueIDsArray).then { cachedSteps -> Promise<[Step]> in
                if Set(cachedSteps.map(\.id)) == uniqueIDs {
                    return .value(cachedSteps)
                } else {
                    return self.stepsNetworkService.fetch(ids: uniqueIDsArray)
                }
            }.done { steps in
                seal.fulfill(steps)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchSubmissions(
        stepID: Step.IdType,
        filterQuery: SubmissionsFilterQuery,
        page: Int
    ) -> Promise<([Submission], Meta)> {
        Promise { seal in
            firstly { () -> Promise<Step> in
                self.fetchStep(id: stepID).compactMap { $0 }
            }.then { step -> Promise<([Submission], Meta)> in
                self.submissionsNetworkService.fetch(
                    stepID: stepID,
                    blockName: step.block.name,
                    filterQuery: filterQuery,
                    page: page
                )
            }.done { submissions, meta in
                seal.fulfill((submissions, meta))
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchAttempts(ids: [Attempt.IdType], stepID: Step.IdType) -> Promise<[Attempt]> {
        if ids.isEmpty {
            return .value([])
        }

        return Promise { seal in
            firstly {
                self.fetchStep(id: stepID).compactMap { $0 }
            }.then { step -> Promise<[Attempt]> in
                self.attemptsNetworkService.fetch(ids: ids, blockName: step.block.name)
            }.done { attempts in
                seal.fulfill(attempts)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchReviewSessions(ids: [Int], stepID: Step.IdType) -> Promise<[ReviewSessionDataPlainObject]> {
        if ids.isEmpty {
            return .value([])
        }

        return Promise { seal in
            firstly {
                self.fetchStep(id: stepID).compactMap { $0 }
            }.then { step -> Promise<[ReviewSessionDataPlainObject]> in
                self.reviewSessionsNetworkService.fetch(ids: ids, blockName: step.block.name)
            }.done { reviewSessions in
                seal.fulfill(reviewSessions)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchReviewSession(
        userID: User.IdType,
        instructionID: Int,
        stepID: Step.IdType
    ) -> Promise<ReviewSessionDataPlainObject?> {
        Promise { seal in
            firstly {
                self.fetchStep(id: stepID).compactMap { $0 }
            }.then { step -> Promise<ReviewSessionDataPlainObject?> in
                self.reviewSessionsNetworkService.fetch(
                    userID: userID,
                    instructionID: instructionID,
                    blockName: step.block.name
                )
            }.done { reviewSession in
                seal.fulfill(reviewSession)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchInstruction(id: Int) -> Promise<InstructionDataPlainObject?> {
        self.instructionsNetworkService.fetch(id: id)
    }

    func fetchUsers(ids: [User.IdType]) -> Promise<[User]> {
        if ids.isEmpty {
            return .value([])
        }

        return Promise { seal in
            self.usersPersistenceService.fetch(ids: ids).then { cachedUsers -> Promise<[User]> in
                if Set(cachedUsers.map(\.id)) == Set(ids) {
                    return .value(cachedUsers)
                }
                return self.usersNetworkService.fetch(ids: ids)
            }.done { users in
                seal.fulfill(users)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    func fetchCurrentUser() -> Guarantee<User?> {
        .value(self.userAccountService.currentUser)
    }

    func getCurrentUserID() -> User.IdType? {
        self.userAccountService.currentUserID
    }

    // MARK: Types

    enum Error: Swift.Error {
        case fetchFailed
    }
}
