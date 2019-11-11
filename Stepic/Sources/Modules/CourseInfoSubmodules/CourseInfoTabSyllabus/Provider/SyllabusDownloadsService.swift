import Foundation
import PromiseKit

protocol SyllabusDownloadsServiceDelegate: class {
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forVideoWithID videoID: Video.IdType
    )
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forUnitWithID unitID: Unit.IdType
    )
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forSectionWithID sectionID: Section.IdType
    )

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forVideoWithID videoID: Video.IdType
    )
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forUnitWithID unitID: Unit.IdType
    )
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forSectionWithID sectionID: Section.IdType
    )

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didFailLoadVideoWithError error: Swift.Error
    )
}

protocol SyllabusDownloadsServiceProtocol: class {
    var delegate: SyllabusDownloadsServiceDelegate? { get set }

    func download(unit: Unit) -> Promise<Void>
    func download(section: Section) -> Promise<Void>

    func remove(unit: Unit) -> Promise<Void>
    func remove(section: Section) -> Promise<Void>

    func cancel(unit: Unit) -> Promise<Void>
    func cancel(section: Section) -> Promise<Void>

    func getDownloadingStateForUnit(_ unit: Unit, in section: Section) -> CourseInfoTabSyllabus.DownloadState
    func getDownloadingStateForSection(_ section: Section) -> CourseInfoTabSyllabus.DownloadState
    func getDownloadingStateForCourse(_ course: Course) -> CourseInfoTabSyllabus.DownloadState
}

final class SyllabusDownloadsService: SyllabusDownloadsServiceProtocol {
    weak var delegate: SyllabusDownloadsServiceDelegate?

    private let videoFileManager: VideoStoredFileManagerProtocol
    private let syllabusDownloadsInteractionService: SyllabusDownloadsInteractionServiceProtocol
    private let stepsNetworkService: StepsNetworkServiceProtocol

    init(
        videoFileManager: VideoStoredFileManagerProtocol,
        syllabusDownloadsInteractionService: SyllabusDownloadsInteractionServiceProtocol,
        stepsNetworkService: StepsNetworkServiceProtocol
    ) {
        self.videoFileManager = videoFileManager
        self.stepsNetworkService = stepsNetworkService

        self.syllabusDownloadsInteractionService = syllabusDownloadsInteractionService
        self.syllabusDownloadsInteractionService.delegate = self
    }

    // MARK: Download

    func download(unit: Unit) -> Promise<Void> {
        guard let lesson = unit.lesson else {
            return Promise(error: Error.lessonNotFound)
        }

        return firstly {
            self.fetchSteps(for: lesson)
        }.done { steps in
            try self.syllabusDownloadsInteractionService.startDownloading(
                syllabusTree: self.makeSyllabusTree(unit: unit, steps: steps)
            )
        }
    }

    func download(section: Section) -> Promise<Void> {
        let hasUncachedUnits = section.units
            .filter { section.unitsArray.contains($0.id) }
            .count != section.unitsArray.count
        if hasUncachedUnits {
            return Promise(error: Error.downloadSectionFailed)
        }

        let fetchStepsPromises = section.units.compactMap { unit -> (Unit, Lesson)? in
            if let lesson = unit.lesson {
                return (unit, lesson)
            }
            return nil
        }.map { result -> Promise<(Unit, [Step])> in
            self.fetchSteps(for: result.1).map { (result.0, $0) }
        }

        return when(
            fulfilled: fetchStepsPromises
        ).done { result in
            result.forEach { unit, steps in
                try? self.syllabusDownloadsInteractionService.startDownloading(
                    syllabusTree: self.makeSyllabusTree(section: section, unit: unit, steps: steps)
                )
            }
        }
    }

    // MARK: Remove

    func remove(unit: Unit) -> Promise<Void> {
        guard let lesson = unit.lesson else {
            return Promise(error: Error.lessonNotFound)
        }

        let removeVideosPromises = lesson.steps
            .filter { $0.block.name == "video" }
            .compactMap { $0.block.video }
            .map { video -> Promise<Void> in
                Promise { seal in
                    do {
                        try self.videoFileManager.removeVideoStoredFile(videoID: video.id)
                        video.cachedQuality = nil
                        seal.fulfill(())
                    } catch {
                        seal.reject(Error.removeUnitFailed)
                    }
                }
            }

        return Promise { seal in
            when(fulfilled: removeVideosPromises).done { _ in
                CoreDataHelper.instance.save()
                seal.fulfill(())
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    func remove(section: Section) -> Promise<Void> {
        return when(
            fulfilled: section.units.map {
                self.remove(unit: $0)
            }
        )
    }

    // MARK: Cancel

    func cancel(unit: Unit) -> Promise<Void> {
        guard let lesson = unit.lesson else {
            return Promise(error: Error.lessonNotFound)
        }

        return self.cancelDownload(section: nil, unit: unit, steps: lesson.steps)
    }

    func cancel(section: Section) -> Promise<Void> {
        return Promise { seal in
            let cancelUnitsPromises = section.units.map { unit -> Promise<Void> in
                guard let lesson = unit.lesson else {
                    return Promise(error: Error.lessonNotFound)
                }

                return self.cancelDownload(section: section, unit: unit, steps: lesson.steps)
            }

            when(fulfilled: cancelUnitsPromises).done {
                seal.fulfill(())
            }.catch { _ in
                seal.reject(Error.cancelSectionFailed)
            }
        }
    }

    // MARK: Downloading state

    func getDownloadingStateForUnit(_ unit: Unit, in section: Section) -> CourseInfoTabSyllabus.DownloadState {
        // If section is unreachable or exam then all units are not available
        guard !section.isExam, section.isReachable else {
            return .notAvailable
        }

        guard let lesson = unit.lesson else {
            // We should call this method only with completely loaded units
            // But return "not cached" in this case
            return .available(isCached: false)
        }

        let steps = lesson.steps

        // If have unloaded steps for lesson then show "not cached" state
        let hasUncachedSteps = steps
            .filter { lesson.stepsArray.contains($0.id) }
            .count != lesson.stepsArray.count
        if hasUncachedSteps {
            return .available(isCached: false)
        }

        // Iterate through steps and determine final state
        let stepsWithVideoCount = steps
            .filter { $0.block.name == "video" }
            .count
        let stepsWithCachedVideoCount = steps
            .filter { $0.block.name == "video" }
            .compactMap { $0.block.video?.id }
            .filter { self.videoFileManager.getVideoStoredFile(videoID: $0) != nil }
            .count

        // Lesson has no steps with video
        if stepsWithVideoCount == 0 {
            return .notAvailable
        }

        // Check if video is downloading
        let stepsWithVideo = steps
            .filter { $0.block.name == "video" }
            .compactMap { $0.block.video }
        let downloadingVideosProgresses = stepsWithVideo.compactMap {
            self.syllabusDownloadsInteractionService.getDownloadProgress(for: $0)
        }

        // TODO: remove calculation, get progress for unit from service
        if !downloadingVideosProgresses.isEmpty {
            return .downloading(
                progress: downloadingVideosProgresses.reduce(0, +) / Float(downloadingVideosProgresses.count)
            )
        }

        // Try to restore downloads
        try? self.syllabusDownloadsInteractionService.restoreDownloading(
            syllabusTree: self.makeSyllabusTree(unit: unit, steps: steps)
        )

        // Some videos aren't cached
        if stepsWithCachedVideoCount != stepsWithVideoCount {
            return .available(isCached: false)
        }

        // All videos are cached
        return .available(isCached: true)
    }

    func getDownloadingStateForSection(_ section: Section) -> CourseInfoTabSyllabus.DownloadState {
        let units = section.units

        // Unreachable and exam not available
        if section.isExam || !section.isReachable {
            return .notAvailable
        }

        // If have unloaded units for lesson then show "not available" state
        let hasUncachedUnits = units
            .filter { section.unitsArray.contains($0.id) }
            .count != section.unitsArray.count
        if hasUncachedUnits {
            return .notAvailable
        }

        let unitStates = units.map { self.getDownloadingStateForUnit($0, in: section) }
        var shouldBeCachedUnitsCount = 0
        var notAvailableUnitsCount = 0
        var downloadingUnitProgresses: [Float] = []

        for state in unitStates {
            switch state {
            case .notAvailable:
                notAvailableUnitsCount += 1
            case .available(let isCached):
                shouldBeCachedUnitsCount += isCached ? 0 : 1
            case .downloading(let progress):
                downloadingUnitProgresses.append(progress)
            default:
                break
            }
        }

        // Downloading state
        if downloadingUnitProgresses.count == units.count && !units.isEmpty {
            return .downloading(
                progress: downloadingUnitProgresses.reduce(0, +) / Float(downloadingUnitProgresses.count)
            )
        }

        // If all units are not available to downloading then section is not available too
        if notAvailableUnitsCount == units.count {
            return .notAvailable
        }

        // If some units are not cached then section is available to downloading
        if shouldBeCachedUnitsCount > 0 {
            return .available(isCached: false)
        }

        // All units are cached, section too
        return .available(isCached: true)
    }

    func getDownloadingStateForCourse(_ course: Course) -> CourseInfoTabSyllabus.DownloadState {
        let sectionStates = course.sections.map { self.getDownloadingStateForSection($0) }

        let containsUncachedSection = sectionStates.contains { state in
            if case .available(let isCached) = state {
                return !isCached
            }
            return false
        }

        return containsUncachedSection ? .available(isCached: false) : .notAvailable
    }

    // MARK: - Private API -

    private func fetchSteps(for lesson: Lesson) -> Promise<[Step]> {
        return firstly {
            self.stepsNetworkService.fetch(ids: lesson.stepsArray)
        }.then { steps -> Promise<[Step]> in
            lesson.steps = steps
            CoreDataHelper.instance.save()
            return .value(steps)
        }
    }

    private func cancelDownload(section: Section?, unit: Unit, steps: [Step]) -> Promise<Void> {
        return Promise { seal in
            do {
                try self.syllabusDownloadsInteractionService.cancelDownloading(
                    syllabusTree: self.makeSyllabusTree(section: section, unit: unit, steps: steps)
                )
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    private func makeSyllabusTree(section: Section? = nil, unit: Unit, steps: [Step]) -> SyllabusTreeNode {
        var stepsTrees: [SyllabusTreeNode] = []
        for step in steps {
            guard step.block.name == "video",
                  let video = step.block.video else {
                continue
            }

            if self.videoFileManager.getVideoStoredFile(videoID: video.id) == nil {
                stepsTrees.append(
                    SyllabusTreeNode(
                        value: .step(id: step.id),
                        children: [SyllabusTreeNode(value: .video(entity: video))]
                    )
                )
            }
        }

        let unitTree = SyllabusTreeNode(
            value: .unit(id: unit.id),
            children: stepsTrees
        )

        if let section = section {
            return SyllabusTreeNode(
                value: .section(id: section.id),
                children: [unitTree]
            )
        }

        return unitTree
    }

    // MARK: - Types -

    enum Error: Swift.Error {
        case lessonNotFound
        case removeUnitFailed
        case downloadSectionFailed
        case cancelSectionFailed
    }
}

// MARK: - SyllabusDownloadsService: SyllabusDownloadsInteractionServiceDelegate -

extension SyllabusDownloadsService: SyllabusDownloadsInteractionServiceDelegate {
    func downloadsInteractionService(
        _ downloadsInteractionService: SyllabusDownloadsInteractionServiceProtocol,
        didReceiveProgress progress: Float,
        source: SyllabusTreeNode.Source
    ) {
        DispatchQueue.main.async {
            switch source {
            case .video(let video):
                self.delegate?.syllabusDownloadsService(self, didReceiveProgress: progress, forVideoWithID: video.id)
            case .unit(let id):
                self.delegate?.syllabusDownloadsService(self, didReceiveProgress: progress, forUnitWithID: id)
            case .section(let id):
                self.delegate?.syllabusDownloadsService(self, didReceiveProgress: progress, forSectionWithID: id)
            default:
                break
            }
        }
    }

    func downloadsInteractionService(
        _ downloadsInteractionService: SyllabusDownloadsInteractionServiceProtocol,
        didReceiveCompletion completed: Bool,
        source: SyllabusTreeNode.Source
    ) {
        DispatchQueue.main.async {
            switch source {
            case .video(let video):
                self.delegate?.syllabusDownloadsService(self, didReceiveCompletion: completed, forVideoWithID: video.id)
            case .unit(let id):
                self.delegate?.syllabusDownloadsService(self, didReceiveCompletion: completed, forUnitWithID: id)
            case .section(let id):
                self.delegate?.syllabusDownloadsService(self, didReceiveCompletion: completed, forSectionWithID: id)
            default:
                break
            }
        }
    }

    func downloadsInteractionService(
        _ downloadsInteractionService: SyllabusDownloadsInteractionServiceProtocol,
        didFailLoadVideo error: Swift.Error
    ) {
        DispatchQueue.main.async {
            self.delegate?.syllabusDownloadsService(self, didFailLoadVideoWithError: error)
        }
    }
}
