//
//  Course.swift
//  
//
//  Created by Alexander Karpov on 25.09.15.
//
//

import CoreData
import Foundation
import PromiseKit
import SwiftyJSON

@objc
final class Course: NSManagedObject, IDFetchable {
    typealias IdType = Int

    var sectionDeadlines: [SectionDeadline]? {
        (PersonalDeadlineLocalStorageManager().getRecord(for: self)?.data as? DeadlineStorageRecordData)?.deadlines
    }

    var metaInfo: String {
        if let progress = self.progress {
            let percentage = progress.numberOfSteps != 0
                ? Int(Double(progress.numberOfStepsPassed) / Double(progress.numberOfSteps) * 100)
                : 100
            return "\(NSLocalizedString("PassedPercent", comment: "")) \(percentage)%"
        } else {
            return ""
        }
    }

    var nearestDeadlines: (nearest: Date?, second: Date?)? {
        if sections.isEmpty {
            return nil
        }

        var deadlinesSet = Set<TimeInterval>()
        for section in sections {
            if let soft = section.softDeadline {
                deadlinesSet.insert(soft.timeIntervalSince1970)
            }
            if let hard = section.hardDeadline {
                deadlinesSet.insert(hard.timeIntervalSince1970)
            }
        }

        let deadlines = deadlinesSet.sorted()

        for (index, deadline) in deadlines.enumerated() {
            if deadline > Date().timeIntervalSince1970 {
                if index + 1 < deadlines.count {
                    return (
                        nearest: Date(timeIntervalSince1970: deadline),
                        second: Date(timeIntervalSince1970: deadlines[index + 1])
                    )
                } else {
                    return (nearest: Date(timeIntervalSince1970: deadline), second: nil)
                }
            }
        }

        return (nearest: nil, second: nil)
    }

    var canContinue: Bool {
        self.totalUnits > 0
            && self.scheduleType != "ended"
            && self.scheduleType != "upcoming"
    }

    var canWriteReview: Bool {
        if let progress = self.progress {
            return (Double(progress.numberOfStepsPassed) * 100.0 / Double(progress.numberOfSteps)) >= 80.0
        }
        return false
    }

    var isPurchased: Bool {
        self.purchases.contains(where: { $0.isActive })
    }

    var anyCertificateTreshold: Int? {
        self.certificateRegularThreshold ?? self.certificateDistinctionThreshold
    }

    var hasCertificate: Bool {
        let hasText = !self.certificate.isEmpty
        let isIssued = self.isCertificatesAutoIssued && self.isCertificateIssued
        return self.anyCertificateTreshold != nil && (hasText || isIssued)
    }

    var defaultPromoCode: PromoCode? {
        if let defaultPromoCodeName = self.defaultPromoCodeName,
           let defaultPromoCodePrice = self.defaultPromoCodePrice {
            return PromoCode(
                courseID: self.id,
                name: defaultPromoCodeName,
                price: defaultPromoCodePrice,
                currencyCode: self.currencyCode ?? "RUB",
                expireDate: self.defaultPromoCodeExpireDate
            )
        }
        return nil
    }

    required convenience init(json: JSON) {
        self.init()
        self.initialize(json)
    }

    func initialize(_ json: JSON) {
        self.id = json[JSONKey.id.rawValue].intValue
        self.title = json[JSONKey.title.rawValue].stringValue
        self.courseDescription = json[JSONKey.description.rawValue].stringValue
        self.coverURLString = "\(StepikApplicationsInfo.stepikURL)" + json[JSONKey.cover.rawValue].stringValue

        self.beginDate = Parser.dateFromTimedateJSON(json[JSONKey.beginDate.rawValue])
        self.endDate = Parser.dateFromTimedateJSON(json[JSONKey.endDate.rawValue])
        self.beginDateSource = Parser.dateFromTimedateJSON(json[JSONKey.beginDateSource.rawValue])
        self.endDateSource = Parser.dateFromTimedateJSON(json[JSONKey.endDateSource.rawValue])

        self.enrolled = json[JSONKey.enrollment.rawValue].int != nil
        self.featured = json[JSONKey.isFeatured.rawValue].boolValue
        self.isPublic = json[JSONKey.isPublic.rawValue].boolValue
        self.isFavorite = json[JSONKey.isFavorite.rawValue].boolValue
        self.isArchived = json[JSONKey.isArchived.rawValue].boolValue
        self.isProctored = json[JSONKey.isProctored.rawValue].boolValue
        self.readiness = json[JSONKey.readiness.rawValue].float

        self.summary = json[JSONKey.summary.rawValue].stringValue
        self.workload = json[JSONKey.workload.rawValue].stringValue
        self.introURL = json[JSONKey.intro.rawValue].stringValue
        self.format = json[JSONKey.courseFormat.rawValue].stringValue
        self.audience = json[JSONKey.targetAudience.rawValue].stringValue
        self.requirements = json[JSONKey.requirements.rawValue].stringValue
        self.slug = json[JSONKey.slug.rawValue].string
        self.progressId = json[JSONKey.progress.rawValue].string
        self.lastStepId = json[JSONKey.lastStep.rawValue].string
        self.scheduleType = json[JSONKey.scheduleType.rawValue].string
        self.learnersCount = json[JSONKey.learnersCount.rawValue].int
        self.totalUnits = json[JSONKey.totalUnits.rawValue].intValue
        self.reviewSummaryId = json[JSONKey.reviewSummary.rawValue].int
        self.sectionsArray = json[JSONKey.sections.rawValue].arrayObject as! [Int]
        self.instructorsArray = json[JSONKey.instructors.rawValue].arrayObject as! [Int]
        self.authorsArray = json[JSONKey.authors.rawValue].arrayObject as? [Int] ?? []
        self.timeToComplete = json[JSONKey.timeToComplete.rawValue].int
        self.languageCode = json[JSONKey.language.rawValue].stringValue
        self.isPaid = json[JSONKey.isPaid.rawValue].boolValue
        self.displayPrice = json[JSONKey.displayPrice.rawValue].string
        self.priceTier = json[JSONKey.priceTier.rawValue].int
        self.currencyCode = json[JSONKey.currencyCode.rawValue].string
        self.previewLessonID = json[JSONKey.previewLesson.rawValue].int
        self.previewUnitID = json[JSONKey.previewUnit.rawValue].int

        self.certificate = json[JSONKey.certificate.rawValue].stringValue
        self.certificateRegularThreshold = json[JSONKey.certificateRegularThreshold.rawValue].int
        self.certificateDistinctionThreshold = json[JSONKey.certificateDistinctionThreshold.rawValue].int
        self.isCertificatesAutoIssued = json[JSONKey.isCertificateAutoIssued.rawValue].boolValue
        self.isCertificateIssued = json[JSONKey.isCertificateIssued.rawValue].boolValue
        self.isWithCertificate = json[JSONKey.withCertificate.rawValue].boolValue

        self.defaultPromoCodeName = json[JSONKey.defaultPromoCodeName.rawValue].string
        self.defaultPromoCodePrice = json[JSONKey.defaultPromoCodePrice.rawValue].decimalNumber?.floatValue
        self.defaultPromoCodeDiscount = json[JSONKey.defaultPromoCodeDiscount.rawValue].decimalNumber?.floatValue
        self.defaultPromoCodeExpireDate = Parser.dateFromTimedateJSON(json[JSONKey.defaultPromoCodeExpireDate.rawValue])

        if let _ = json[JSONKey.introVideo.rawValue].null {
            self.introVideo = nil
        } else {
            self.introVideo = Video(json: json[JSONKey.introVideo.rawValue])
        }

        if let actionsDictionary = json[JSONKey.actions.rawValue].dictionary {
            self.canViewRevenue =
                actionsDictionary[JSONKey.viewRevenue.rawValue]?.dictionary?[JSONKey.enabled.rawValue]?.bool ?? false
        } else {
            self.canViewRevenue = false
        }
    }

    func update(json: JSON) {
        self.initialize(json)
    }

    @available(*, deprecated, message: "Legacy")
    func loadAllInstructors(success: @escaping (() -> Void)) {
        _ = ApiDataDownloader.users.retrieve(
            ids: self.instructorsArray,
            existing: self.instructors,
            refreshMode: .update,
            success: { users in
                self.instructors = Sorter.sort(users, byIds: self.instructorsArray)
                CoreDataHelper.shared.save()
                success()
            },
            error: { _ in
                print("error while loading section")
            }
        )
    }

    @available(*, deprecated, message: "Legacy")
    func loadAllSections(
        success: @escaping (() -> Void),
        error errorHandler : @escaping (() -> Void),
        withProgresses: Bool = true
    ) {
        if sectionsArray.isEmpty {
            success()
            return
        }

        let requestSectionsCount = 50
        var dimCount = 0
        var idsArray = [[Int]]()
        for (index, sectionId) in self.sectionsArray.enumerated() {
            if index % requestSectionsCount == 0 {
                idsArray.append([Int]())
                dimCount += 1
            }
            idsArray[dimCount - 1].append(sectionId)
        }

        var downloadedSections = [Section]()

        let idsDownloaded: ([Section]) -> Void = {
            secs in
            downloadedSections.append(contentsOf: secs)
            if downloadedSections.count == self.sectionsArray.count {
                self.sections = Sorter.sort(downloadedSections, byIds: self.sectionsArray)
                CoreDataHelper.shared.save()
                success()
            }
        }

        var wasError = false
        let errorWhileDownloading : () -> Void = {
            if !wasError {
                wasError = true
                errorHandler()
            }
        }

        for ids in idsArray {
            _ = ApiDataDownloader.sections.retrieve(ids: ids, existing: self.sections, refreshMode: .update, success: {
                secs in
                if withProgresses {
                    self.loadProgressesForSections(sections: secs, success: {
                        idsDownloaded(secs)
                    }, error: {
                        errorWhileDownloading()
                    })
                } else {
                    idsDownloaded(secs)
                }
            }, error: {
                _ in
                print("error while loading section")
                errorWhileDownloading()
            })
        }
    }

    @available(*, deprecated, message: "Legacy")
    func loadProgressesForSections(
        sections: [Section],
        success completion: @escaping (() -> Void),
        error errorHandler : @escaping (() -> Void)
    ) {
        var progressIds: [String] = []
        var progresses: [Progress] = []
        for section in sections {
            if let progressId = section.progressId {
                progressIds += [progressId]
            }

            if let progress = section.progress {
                progresses += [progress]
            }
        }

        if progressIds.count == 0 {
            completion()
            return
        }

        _ = ApiDataDownloader.progresses.retrieve(ids: progressIds, existing: progresses, refreshMode: .update, success: {
            newProgresses -> Void in
            progresses = Sorter.sort(newProgresses, byIds: progressIds)

            if progresses.count == 0 {
                CoreDataHelper.shared.save()
                completion()
                return
            }

            var progressCnt = 0
            for i in 0 ..< sections.count {
                if sections[i].progressId == progresses[progressCnt].id {
                    sections[i].progress = progresses[progressCnt]
                    progressCnt += 1
                }
                if progressCnt == progresses.count {
                    break
                }
            }
            CoreDataHelper.shared.save()
            completion()
        }, error: {
            (_) -> Void in
            print("Error while downloading progresses")
            errorHandler()
        })
    }

    static func fetch(
        _ ids: [Int],
        featured: Bool? = nil,
        enrolled: Bool? = nil,
        isPublic: Bool? = nil
    ) -> [Course] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Course")
        let descriptor = NSSortDescriptor(key: "managedId", ascending: false)

        let idPredicates = ids.map {
            NSPredicate(format: "managedId == %@", $0 as NSNumber)
        }
        let idCompoundPredicate = NSCompoundPredicate(type: .or, subpredicates: idPredicates)

        var nonIdPredicates = [NSPredicate]()
        if let f = featured {
            nonIdPredicates += [NSPredicate(format: "managedFeatured == %@", f as NSNumber)]
        }

        if let e = enrolled {
            nonIdPredicates += [NSPredicate(format: "managedEnrolled == %@", e as NSNumber)]
        }

        if let p = isPublic {
            nonIdPredicates += [NSPredicate(format: "managedPublic == %@", p as NSNumber)]
        }

        let nonIdCompoundPredicate = NSCompoundPredicate(type: .and, subpredicates: nonIdPredicates)

        let predicate = NSCompoundPredicate(type: .and, subpredicates: [idCompoundPredicate, nonIdCompoundPredicate])
        request.predicate = predicate
        request.sortDescriptors = [descriptor]

        do {
            let results = try CoreDataHelper.shared.context.fetch(request)
            let finalResult = results as? [Course] ?? []

            return finalResult
        } catch {
            return []
        }
    }

    static func getAllCourses(enrolled: Bool? = nil) -> [Course] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Course")
        var predicate = NSPredicate(value: true)

        if let enrolled = enrolled {
            let enrolledPredicate = NSPredicate(format: "managedEnrolled == %@", enrolled as NSNumber)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, enrolledPredicate])
        }

        request.predicate = predicate

        do {
            let results = try CoreDataHelper.shared.context.fetch(request)
            return results as! [Course]
        } catch {
            print("Error while getting courses")
            return []
        }
    }

    func getSection(before section: Section) -> Section? {
        let currentIndex = sectionsArray.firstIndex(of: section.id)
        if currentIndex == nil || currentIndex == sectionsArray.startIndex {
            return nil
        } else {
            let prevId = sectionsArray[currentIndex!.advanced(by: -1)]
            return sections.filter({ $0.id == prevId }).first
        }
    }

    func getSection(after section: Section) -> Section? {
        let currentIndex = sectionsArray.firstIndex(of: section.id)
        if currentIndex == nil || currentIndex == sectionsArray.endIndex.advanced(by: -1) {
            return nil
        } else {
            let nextId = sectionsArray[currentIndex!.advanced(by: 1)]
            return sections.filter({ $0.id == nextId }).first
        }
    }

    // MARK: Inner Types

    enum JSONKey: String {
        case id
        case title
        case description
        case cover
        case beginDate = "begin_date"
        case endDate = "end_date"
        case beginDateSource = "begin_date_source"
        case endDateSource = "end_date_source"
        case enrollment
        case isFeatured = "is_featured"
        case isPublic = "is_public"
        case isFavorite = "is_favorite"
        case isArchived = "is_archived"
        case readiness
        case summary
        case workload
        case intro
        case courseFormat = "course_format"
        case targetAudience = "target_audience"
        case certificate
        case certificateRegularThreshold = "certificate_regular_threshold"
        case certificateDistinctionThreshold = "certificate_distinction_threshold"
        case isCertificateAutoIssued = "is_certificate_auto_issued"
        case isCertificateIssued = "is_certificate_issued"
        case withCertificate = "with_certificate"
        case requirements
        case slug
        case progress
        case lastStep = "last_step"
        case scheduleType = "schedule_type"
        case learnersCount = "learners_count"
        case totalUnits = "total_units"
        case reviewSummary = "review_summary"
        case sections
        case instructors
        case authors
        case timeToComplete = "time_to_complete"
        case language
        case isPaid = "is_paid"
        case displayPrice = "display_price"
        case currencyCode = "currency_code"
        case introVideo = "intro_video"
        case priceTier = "price_tier"
        case previewLesson = "preview_lesson"
        case previewUnit = "preview_unit"
        case isProctored = "is_proctored"
        case defaultPromoCodeName = "default_promo_code_name"
        case defaultPromoCodePrice = "default_promo_code_price"
        case defaultPromoCodeDiscount = "default_promo_code_discount"
        case defaultPromoCodeExpireDate = "default_promo_code_expire_date"
        case actions
        case viewRevenue = "view_revenue"
        case enabled
    }
}
