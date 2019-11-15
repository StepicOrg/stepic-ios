import Foundation
import PromiseKit

// swiftlint:disable file_length
protocol CourseInfoTabSyllabusInteractorProtocol {
    func doSectionsFetch(request: CourseInfoTabSyllabus.SyllabusLoad.Request)
    func doSectionFetch(request: CourseInfoTabSyllabus.SyllabusSectionLoad.Request)
    func doDownloadButtonAction(request: CourseInfoTabSyllabus.DownloadButtonAction.Request)
    func doUnitSelection(request: CourseInfoTabSyllabus.UnitSelection.Request)
    func doPersonalDeadlinesAction(request: CourseInfoTabSyllabus.PersonalDeadlinesButtonAction.Request)
}

final class CourseInfoTabSyllabusInteractor: CourseInfoTabSyllabusInteractorProtocol {
    weak var moduleOutput: CourseInfoTabSyllabusOutputProtocol?

    private let presenter: CourseInfoTabSyllabusPresenterProtocol
    private let provider: CourseInfoTabSyllabusProviderProtocol
    private let personalDeadlinesService: PersonalDeadlinesServiceProtocol
    private let nextLessonService: NextLessonServiceProtocol
    private let tooltipStorageManager: TooltipStorageManagerProtocol
    private let syllabusDownloadsService: SyllabusDownloadsServiceProtocol

    private var currentCourse: Course?
    private var currentSections: [UniqueIdentifierType: Section] = [:] {
        didSet {
            self.refreshNextLessonService()
        }
    }

    private var currentUnits: [UniqueIdentifierType: Unit?] = [:] {
        didSet {
            self.refreshNextLessonService()
        }
    }

    private var isOnline = false {
        willSet {
            if !newValue && self.isOnline {
                fatalError("Online -> offline transition not supported")
            }
        }
    }
    private var didLoadFromNetwork = false {
        willSet {
            if !newValue && self.didLoadFromNetwork {
                fatalError("Online -> offline transition not supported")
            }
        }
    }

    private var shouldOpenedAnalyticsEventSend = false

    private var reportedToAnalyticsVideoDownloadIds = Set<Video.IdType>()

    // Fetch syllabus only after previous fetch completed
    private let fetchSemaphore = DispatchSemaphore(value: 1)
    // Online mode: fetch section only when offline fetching completed
    private let sectionFetchSemaphore = DispatchSemaphore(value: 0)

    private lazy var sectionsFetchBackgroundQueue = DispatchQueue(
        label: "com.AlexKarpov.Stepic.CourseInfoTabSyllabusInteractor.SectionsFetch"
    )
    private lazy var unitsFetchBackgroundQueue = DispatchQueue(
        label: "com.AlexKarpov.Stepic.CourseInfoTabSyllabusInteractor.UnitsFetch"
    )

    init(
        presenter: CourseInfoTabSyllabusPresenterProtocol,
        provider: CourseInfoTabSyllabusProviderProtocol,
        personalDeadlinesService: PersonalDeadlinesServiceProtocol,
        nextLessonService: NextLessonServiceProtocol,
        tooltipStorageManager: TooltipStorageManagerProtocol,
        syllabusDownloadsService: SyllabusDownloadsServiceProtocol
    ) {
        self.presenter = presenter
        self.provider = provider
        self.personalDeadlinesService = personalDeadlinesService
        self.nextLessonService = nextLessonService
        self.tooltipStorageManager = tooltipStorageManager

        self.syllabusDownloadsService = syllabusDownloadsService
        self.syllabusDownloadsService.delegate = self
    }

    // MARK: - Public API

    func doSectionsFetch(request: CourseInfoTabSyllabus.SyllabusLoad.Request) {
        guard let course = self.currentCourse else {
            return
        }

        self.sectionsFetchBackgroundQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.fetchSemaphore.wait()

            let isOnline = strongSelf.isOnline
            print("course info tab syllabus interactor: start fetching syllabus, isOnline = \(isOnline)")

            strongSelf.fetchSyllabusInAppropriateMode(course: course, isOnline: isOnline).done { response in
                DispatchQueue.main.async {
                    print("course info tab syllabus interactor: finish fetching syllabus, isOnline = \(isOnline)")

                    strongSelf.presenter.presentCourseSyllabus(response: response)

                    if isOnline && !strongSelf.didLoadFromNetwork {
                        strongSelf.didLoadFromNetwork = true
                        strongSelf.updateSyllabusHeader()
                        strongSelf.sectionFetchSemaphore.signal()
                    }
                }
            }.catch { _ in
                // TODO: handle
            }.finally {
                strongSelf.fetchSemaphore.signal()
            }
        }
    }

    func doSectionFetch(request: CourseInfoTabSyllabus.SyllabusSectionLoad.Request) {
        self.unitsFetchBackgroundQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            // Check whether section fetching completed
            strongSelf.sectionFetchSemaphore.wait()
            strongSelf.sectionFetchSemaphore.signal()

            guard let section = strongSelf.currentSections[request.uniqueIdentifier] else {
                return
            }

            print("course info tab syllabus interactor: start fetching section from network, id = \(section.id)")

            strongSelf.fetchSyllabusSection(section: section).done { response in
                DispatchQueue.main.async {
                    print("course info tab syllabus interactor: finish fetching section from network, id = \(section.id)")
                    strongSelf.presenter.presentCourseSyllabus(response: response)
                    strongSelf.updateSyllabusHeader()
                }
            }.catch { error in
                print("course info tab syllabus interactor: error while fetching section from network, error = \(error)")
            }
        }
    }

    func doDownloadButtonAction(request: CourseInfoTabSyllabus.DownloadButtonAction.Request) {
        func handleUnit(id: UniqueIdentifierType) {
            guard let unit = self.currentUnits[id] as? Unit else {
                print("course info tab syllabus interactor: unit doesn't exist in current units, id = \(id)")
                return
            }

            let currentState = self.getDownloadingState(for: unit)
            switch currentState {
            case .available(let isCached):
                if isCached {
                    self.presenter.presentDeleteDownloadsConfirmationAlert(
                        response: .init(
                            type: .unit,
                            cancelActionHandler: {
                                AmplitudeAnalyticsEvents.Downloads.deleteDownloadsConfirmationInteracted(
                                    content: .lesson, isConfirmed: false
                                ).send()
                            },
                            confirmedActionHandler: { [weak self] in
                                AmplitudeAnalyticsEvents.Downloads.deleteDownloadsConfirmationInteracted(
                                    content: .lesson, isConfirmed: true
                                ).send()
                                self?.removeCached(unit: unit)
                            }
                        )
                    )
                } else {
                    self.startDownloading(unit: unit)
                }
            case .downloading:
                self.cancelDownloading(unit: unit)
            default:
                break
            }
        }

        func handleSection(id: UniqueIdentifierType) {
            guard let section = self.currentSections[id] else {
                print("course info tab syllabus interactor: section doesn't exist in current sections, id = \(id)")
                return
            }

            let currentState = self.getDownloadingState(for: section)
            switch currentState {
            case .available(let isCached):
                if isCached {
                    self.presenter.presentDeleteDownloadsConfirmationAlert(
                        response: .init(
                            type: .section,
                            cancelActionHandler: {
                                AmplitudeAnalyticsEvents.Downloads.deleteDownloadsConfirmationInteracted(
                                    content: .section, isConfirmed: false
                                ).send()
                            },
                            confirmedActionHandler: { [weak self] in
                                AmplitudeAnalyticsEvents.Downloads.deleteDownloadsConfirmationInteracted(
                                    content: .section, isConfirmed: true
                                ).send()
                                self?.removeCached(section: section)
                            }
                        )
                    )
                } else {
                    self.startDownloading(section: section)
                }
            case .downloading:
                self.cancelDownloading(section: section)
            default:
                break
            }
        }

        func handleAll() {
            AmplitudeAnalyticsEvents.Downloads.started(content: .course).send()
            self.presenter.presentWaitingState(response: .init(shouldDismiss: false))
            self.forceLoadAllSectionsIfNeeded().done {
                for (uid, section) in self.currentSections {
                    let sectionState = self.getDownloadingState(for: section)
                    if case .available(let isCached) = sectionState, !isCached {
                        handleSection(id: uid)
                    }
                }
                self.updateSyllabusHeader(shouldForceDisableDownloadAll: true)
            }.ensure {
                self.presenter.presentWaitingState(response: .init(shouldDismiss: true))
            }.catch { error in
                self.presenter.presentFailedVideoDownloadAlert(response: .init(error: error))
            }
        }

        switch request.type {
        case .all:
            return handleAll()
        case .section(let uniqueIdentifier):
            return handleSection(id: uniqueIdentifier)
        case .unit(let uniqueIdentifier):
            return handleUnit(id: uniqueIdentifier)
        }
    }

    func doUnitSelection(request: CourseInfoTabSyllabus.UnitSelection.Request) {
        guard let unit = self.currentUnits[request.uniqueIdentifier] as? Unit else {
            return
        }
        self.requestUnitPresentation(unit)
    }

    func doPersonalDeadlinesAction(request: CourseInfoTabSyllabus.PersonalDeadlinesButtonAction.Request) {
        guard let course = self.currentCourse else {
            return
        }

        if self.personalDeadlinesService.hasDeadlines(in: course) {
            self.moduleOutput?.presentPersonalDeadlinesSettings(for: course)
        } else {
            AmplitudeAnalyticsEvents.PersonalDeadlines.buttonClicked.send()
            self.moduleOutput?.presentPersonalDeadlinesCreation(for: course)
        }
    }

    // MARK: - Private API

    private func forceLoadAllSectionsIfNeeded() -> Promise<Void> {
        let allSections = Array(self.currentSections.values)
        let allUnits = allSections.map { $0.unitsArray }.reduce([], +)
        let availableUnits = self.currentUnits.values.compactMap { $0?.id }

        return Promise { seal in
            if availableUnits.sorted() == allUnits.sorted() {
                seal.fulfill(())
            } else {
                // Load all units in each section
                let unitsPromises = self.currentSections.values.map { self.fetchSyllabusSection(section: $0) }
                when(fulfilled: unitsPromises).done { _ in
                    seal.fulfill(())
                }.catch { error in
                    seal.reject(error)
                }
            }
        }
    }

    private func updateSyllabusHeader(shouldForceDisableDownloadAll: Bool = false) {
        guard let course = self.currentCourse else {
            return
        }

        let isPersonalDeadlinesAvailable = self.personalDeadlinesService.canAddDeadlines(in: course)
            || self.personalDeadlinesService.hasDeadlines(in: course)

        let isDownloadAllAvailable: Bool = {
            if case .available(_) = self.getDownloadingStateForCourse() {
                return true
            }
            return false
        }() && !shouldForceDisableDownloadAll
        self.presenter.presentCourseSyllabusHeader(
            response: .init(
                isPersonalDeadlinesAvailable: isPersonalDeadlinesAvailable,
                isDownloadAllAvailable: isDownloadAllAvailable,
                isPersonalDeadlinesTooltipVisible: !self.tooltipStorageManager.didShowOnPersonalDeadlinesButton
            )
        )

        self.tooltipStorageManager.didShowOnPersonalDeadlinesButton = true
    }

    private func fetchSyllabusSection(
        section: Section
    ) -> Promise<CourseInfoTabSyllabus.SyllabusLoad.Response> {
        return Promise { seal in
            self.provider.fetchUnitsWithLessons(
                for: section,
                shouldUseNetwork: true
            ).done { units in
                self.updateCurrentData(units: units, shouldRemoveAll: false)

                let data = self.makeSyllabusDataFromCurrentData()
                seal.fulfill(.init(result: .success(data)))
            }.catch { error in
                print("course info tab syllabus interactor: unable to fetch section, error = \(error)")
                seal.reject(Error.fetchFailed)
            }
        }
    }

    private func fetchSyllabusInAppropriateMode(
        course: Course,
        isOnline: Bool
    ) -> Promise<CourseInfoTabSyllabus.SyllabusLoad.Response> {
        return Promise { seal in
            // Load sections & progresses
            self.provider.fetchSections(for: course, shouldUseNetwork: isOnline).then {
                sections -> Promise<([Section], [[Unit]])> in
                // In offline mode load units & lessons just now
                // In online mode load units & lessons on demand

                let offlineUnitsPromise = when(
                    fulfilled: sections.map { section in
                        self.provider.fetchUnitsWithLessons(for: section, shouldUseNetwork: false)
                    }
                )
                let onlineUnitsPromise = Promise.value([[Unit]]())

                let unitsPromise = isOnline ? onlineUnitsPromise : offlineUnitsPromise
                return unitsPromise.map { (sections, $0) }
            }.done { result in
                let sections = result.0
                let units = Array(result.1.joined())

                self.updateCurrentData(sections: sections, units: units, shouldRemoveAll: true)

                let data = self.makeSyllabusDataFromCurrentData()
                seal.fulfill(.init(result: .success(data)))
            }.catch { error in
                print("course info tab syllabus interactor: unable to fetch syllabus, error = \(error)")
                seal.reject(Error.fetchFailed)
            }
        }
    }

    // swiftlint:disable:next discouraged_optional_collection
    private func updateCurrentData(sections: [Section]? = nil, units: [Unit], shouldRemoveAll: Bool) {
        if shouldRemoveAll {
            self.currentSections.removeAll(keepingCapacity: true)
            self.currentUnits.removeAll(keepingCapacity: true)
        }

        for section in sections ?? [] {
            self.currentSections[self.getUniqueIdentifierBySectionID(section.id)] = section
            for unitID in section.unitsArray {
                self.currentUnits[self.getUniqueIdentifierByUnitID(unitID)] = nil
            }
        }

        for unit in units {
            self.currentUnits[self.getUniqueIdentifierByUnitID(unit.id)] = unit
        }
    }

    private func makeSyllabusDataFromCurrentData() -> CourseInfoTabSyllabus.SyllabusData {
        return CourseInfoTabSyllabus.SyllabusData(
            sections: self.currentSections
                .map { uid, entity in
                    .init(uniqueIdentifier: uid, entity: entity, downloadState: self.getDownloadingState(for: entity))
                }
                .sorted(by: { $0.entity.position < $1.entity.position }),
            units: self.currentUnits
                .map { uid, entity in
                    var state: CourseInfoTabSyllabus.DownloadState
                    if let unit = entity {
                        state = self.getDownloadingState(for: unit)
                    } else {
                        state = .notAvailable
                    }

                    return .init(uniqueIdentifier: uid, entity: entity, downloadState: state)
                }
                .sorted(by: { ($0.entity?.position ?? 0) < ($1.entity?.position ?? 0) }),
            sectionsDeadlines: self.currentCourse?.sectionDeadlines ?? [],
            isEnrolled: self.currentCourse?.enrolled ?? false
        )
    }

    private func getUniqueIdentifierBySectionID(_ sectionID: Section.IdType) -> UniqueIdentifierType {
        return "\(sectionID)"
    }

    private func getUniqueIdentifierByUnitID(_ unitID: Unit.IdType) -> UniqueIdentifierType {
        return "\(unitID)"
    }

    private func refreshNextLessonService() {
        let orderedSections = self.currentSections.values.sorted(by: { $0.position < $1.position })
        self.nextLessonService.configure(with: orderedSections)
    }

    private func requestUnitPresentation(_ unit: Unit) {
        // Check whether unit is in exam section
        if let section = self.currentSections[self.getUniqueIdentifierBySectionID(unit.sectionId)],
           section.isExam, section.isReachable {
            self.moduleOutput?.presentExamLesson()
            return
        }

        self.moduleOutput?.presentLesson(in: unit)
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}

// MARK: - CourseInfoTabSyllabusInteractor: CourseInfoTabSyllabusInputProtocol -

extension CourseInfoTabSyllabusInteractor: CourseInfoTabSyllabusInputProtocol {
    func handleControllerAppearance() {
        if let course = self.currentCourse {
            AmplitudeAnalyticsEvents.Sections.opened(courseID: course.id, courseTitle: course.title).send()
            self.shouldOpenedAnalyticsEventSend = false
        } else {
            self.shouldOpenedAnalyticsEventSend = true
        }
    }

    func update(with course: Course, isOnline: Bool) {
        print("course info tab syllabus interactor: updated from parent module, isOnline = \(isOnline)")
        self.currentCourse = course
        self.isOnline = isOnline
        self.doSectionsFetch(request: .init())

        if self.shouldOpenedAnalyticsEventSend {
            AmplitudeAnalyticsEvents.Sections.opened(courseID: course.id, courseTitle: course.title).send()
            self.shouldOpenedAnalyticsEventSend = false
        }
    }
}

// MARK: - CourseInfoTabSyllabusInteractor: SectionNavigationDelegate -

extension CourseInfoTabSyllabusInteractor: SectionNavigationDelegate {
    func didRequestPreviousUnitPresentationForLessonInUnit(unitID: Unit.IdType) {
        guard let unit = self.currentUnits[self.getUniqueIdentifierByUnitID(unitID)] as? Unit,
              let previousUnit = self.nextLessonService.findPreviousUnit(for: unit) as? Unit else {
            return
        }

        self.requestUnitPresentation(previousUnit)
    }

    func didRequestNextUnitPresentationForLessonInUnit(unitID: Unit.IdType) {
        guard let unit = self.currentUnits[self.getUniqueIdentifierByUnitID(unitID)] as? Unit,
              let nextUnit = self.nextLessonService.findNextUnit(for: unit) as? Unit else {
            return
        }

        self.requestUnitPresentation(nextUnit)
    }
}

// MARK: - CourseInfoTabSyllabusInteractor: SyllabusDownloadsServiceDelegate -

extension CourseInfoTabSyllabusInteractor: SyllabusDownloadsServiceDelegate {
    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forVideoWithID videoID: Video.IdType
    ) {
        if !self.reportedToAnalyticsVideoDownloadIds.contains(videoID) {
            self.reportedToAnalyticsVideoDownloadIds.insert(videoID)
            AnalyticsReporter.reportEvent(AnalyticsEvents.VideoDownload.started)
        }
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forUnitWithID unitID: Unit.IdType
    ) {
        guard let unit = self.currentUnits[self.getUniqueIdentifierByUnitID(unitID)] as? Unit else {
            return
        }

        self.presenter.presentDownloadButtonUpdate(
            response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                source: .unit(entity: unit),
                downloadState: .downloading(progress: progress)
            )
        )
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveProgress progress: Float,
        forSectionWithID sectionID: Section.IdType
    ) {
        guard let section = self.currentSections[self.getUniqueIdentifierBySectionID(sectionID)] else {
            return
        }

        self.presenter.presentDownloadButtonUpdate(
            response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                source: .section(entity: section),
                downloadState: .downloading(progress: progress)
            )
        )
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forVideoWithID videoID: Video.IdType
    ) {
        self.reportedToAnalyticsVideoDownloadIds.remove(videoID)
        AnalyticsReporter.reportEvent(AnalyticsEvents.VideoDownload.succeeded)
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forUnitWithID unitID: Unit.IdType
    ) {
        guard let unit = self.currentUnits[self.getUniqueIdentifierByUnitID(unitID)] as? Unit else {
            return
        }

        self.presenter.presentDownloadButtonUpdate(
            response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                source: .unit(entity: unit),
                downloadState: .available(isCached: isCompleted)
            )
        )
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didReceiveCompletion isCompleted: Bool,
        forSectionWithID sectionID: Section.IdType
    ) {
        guard let section = self.currentSections[self.getUniqueIdentifierBySectionID(sectionID)] else {
            return
        }

        self.presenter.presentDownloadButtonUpdate(
            response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                source: .section(entity: section),
                downloadState: .available(isCached: isCompleted)
            )
        )
    }

    func syllabusDownloadsService(
        _ service: SyllabusDownloadsServiceProtocol,
        didFailLoadVideoWithError error: Swift.Error
    ) {
        func report(_ error: Swift.Error, reason: AnalyticsEvents.VideoDownload.Reason) {
            let nsError = error as NSError
            AnalyticsReporter.reportEvent(
                AnalyticsEvents.VideoDownload.failed,
                parameters: [
                    "description": nsError.localizedDescription,
                    "name": String(describing: error),
                    "code": nsError.code,
                    "domain": nsError.domain,
                    "reason": reason.rawValue
                ]
            )
        }

        if case VideoDownloadingService.Error.videoDownloadingStopped = error {
            report(error, reason: .cancelled)
        } else {
            let nsError = error as NSError
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == 100 {
                report(error, reason: .protocolError)
            } else if !self.isOnline {
                report(error, reason: .offline)
            } else {
                report(error, reason: .other)
            }

            self.presenter.presentFailedVideoDownloadAlert(response: .init(error: error))
        }
    }
}

// MARK: - Video managing & downloading -

extension CourseInfoTabSyllabusInteractor {
    private func cancelDownloading(unit: Unit) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Unit.cancel, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.cancelled(content: .lesson).send()

        self.syllabusDownloadsService.cancel(unit: unit).done {
            print("course info tab syllabus interactor: successfully cancelled unit")
        }.catch { error in
            print("course info tab syllabus interactor: error while cancelling unit: \(error)")
        }
    }

    private func cancelDownloading(section: Section) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Section.cancel, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.cancelled(content: .section).send()

        self.syllabusDownloadsService.cancel(section: section).done {
            print("course info tab syllabus interactor: successfully cancelled section")
        }.catch { error in
            print("course info tab syllabus interactor: error while cancelling section: \(error)")
        }
    }

    private func removeCached(unit: Unit) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Unit.delete, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.deleted(content: .lesson).send()

        self.syllabusDownloadsService.remove(unit: unit).done {
            print("course info tab syllabus interactor: successfully removed unit")
        }.ensure {
            self.presenter.presentDownloadButtonUpdate(
                response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                    source: .unit(entity: unit),
                    downloadState: self.getDownloadingState(for: unit)
                )
            )
        }.catch { error in
            print("course info tab syllabus interactor: error while unit file removing = \(error)")
        }
    }

    private func removeCached(section: Section) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Section.delete, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.deleted(content: .section).send()

        self.syllabusDownloadsService.remove(section: section).done {
            print("course info tab syllabus interactor: successfully removed section")
        }.ensure {
            section.units.forEach { unit in
                self.presenter.presentDownloadButtonUpdate(
                    response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                        source: .unit(entity: unit),
                        downloadState: self.getDownloadingState(for: unit)
                    )
                )
            }
            self.presenter.presentDownloadButtonUpdate(
                response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                    source: .section(entity: section),
                    downloadState: self.getDownloadingState(for: section)
                )
            )
        }.catch { error in
            print("course info tab syllabus interactor: error while section files removing = \(error)")
        }
    }

    private func startDownloading(unit: Unit) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Unit.cache, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.started(content: .lesson).send()

        self.presenter.presentDownloadButtonUpdate(
            response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                source: .unit(entity: unit),
                downloadState: .waiting
            )
        )

        self.syllabusDownloadsService.download(unit: unit).done {
            print("course info tab syllabus interactor: started downloading unit")
        }.catch { error in
            self.presenter.presentDownloadButtonUpdate(
                response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                    source: .unit(entity: unit),
                    downloadState: .available(isCached: false)
                )
            )
            self.presenter.presentFailedVideoDownloadAlert(response: .init(error: error))
        }
    }

    private func startDownloading(section: Section) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Section.cache, parameters: nil)
        AmplitudeAnalyticsEvents.Downloads.started(content: .section).send()

        self.syllabusDownloadsService.download(section: section).done {
            print("course info tab syllabus interactor: started downloading section")
        }.ensure {
            section.units.forEach { unit in
                self.presenter.presentDownloadButtonUpdate(
                    response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                        source: .unit(entity: unit),
                        downloadState: self.getDownloadingState(for: unit)
                    )
                )
            }
            self.presenter.presentDownloadButtonUpdate(
                response: CourseInfoTabSyllabus.DownloadButtonStateUpdate.Response(
                    source: .section(entity: section),
                    downloadState: .available(isCached: false)
                )
            )
        }.catch { error in
            self.presenter.presentFailedVideoDownloadAlert(response: .init(error: error))
        }
    }

    private func getDownloadingState(for unit: Unit) -> CourseInfoTabSyllabus.DownloadState {
        if let section = self.currentSections[self.getUniqueIdentifierBySectionID(unit.sectionId)] {
            return self.syllabusDownloadsService.getDownloadStateForUnit(unit, section: section)
        }
        return .notAvailable
    }

    private func getDownloadingStateForCourse() -> CourseInfoTabSyllabus.DownloadState {
        if let course = self.currentCourse {
            return self.syllabusDownloadsService.getDownloadStateForCourse(course)
        }
        return .notAvailable
    }

    private func getDownloadingState(for section: Section) -> CourseInfoTabSyllabus.DownloadState {
        return self.syllabusDownloadsService.getDownloadStateForSection(section)
    }
}
