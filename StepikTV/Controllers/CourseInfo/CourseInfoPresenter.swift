//
//  CourseInfoPresenter.swift
//  StepikTV
//
//  Created by Александр Пономарев on 17.12.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import PromiseKit

let MinTimeDelayInSeconds: Double = 1.0

class CourseInfoPresenter {

    private weak var view: CourseInfoView?
    private var subscriber: CourseSubscriber

    var course: Course? {
        didSet {
            guard let course = course else { return }
            view?.showLoading(title: course.title)
            let beginLoadTimestamp = Date().timeIntervalSince1970

            course.loadAllInstructors {
                let endLoadTimestamp = Date().timeIntervalSince1970
                let spendedTime = endLoadTimestamp - beginLoadTimestamp
                let diff = max(MinTimeDelayInSeconds - spendedTime, 0)

                self.instructors = course.instructors
                self.view?.provide(sections: self.buildSections(with: course))

                DispatchQueue.main.asyncAfter(deadline: .now() + diff) {
                    [weak self] in
                    self?.view?.hideLoading()
                }
            }
        }
    }
    private var instructors: [User] = []
    private var sections: [CourseInfoSection] = []

    private let subscribeTitle = NSLocalizedString("Subscribing...", comment: "")
    private let unsubscribeTitle = NSLocalizedString("Unsubscribing...", comment: "")

    init(view: CourseInfoView, subscriber: CourseSubscriber) {
        self.view = view
        self.subscriber = subscriber
    }

    private func buildSections(with course: Course) -> [CourseInfoSection] {
        guard let viewController = view as? UIViewController else { fatalError() }

        var sections: [CourseInfoSection] = []

        let textSelectionAction: (TVFocusableText) -> Void = {
            let textPresenter = TVTextPresentationAlertController()
            textPresenter.setText($0.text ?? "")
            textPresenter.modalPresentationStyle = .overFullScreen
            viewController.present(textPresenter, animated: true, completion: {})
        }

        // Main section
        let isAuthorized = AuthInfo.shared.isAuthorized
        let mainSection = createMainSection(course: course, isAuthorized: isAuthorized, selectionAction: textSelectionAction)
        sections.append(mainSection)

        // Instructors section
        if let instructorsSections = createInstructorsSection(selectionAction: textSelectionAction) {
            sections.append(instructorsSections)
        }

        // Details sections
        let detailsSections = createDetailSections(course: course, selectionAction: textSelectionAction)
        sections.append(contentsOf: detailsSections)

        return sections
    }

    private func createMainSection(course: Course, isAuthorized: Bool, selectionAction: @escaping (TVFocusableText) -> Void) -> CourseInfoSection {
        let title = course.title
        var hostname: String = ""
        if let host = course.instructors.first { hostname = "\(host.lastName) \(host.firstName)"}
        let descr = course.courseDescription
        let imageURL = URL(string: course.coverURLString)

        var trailerAction: (() -> Void)?
        if let intro = course.introVideo {
            trailerAction = {
                self.playIntro(intro: intro)
            }
        }

        let subscriptionAction: () -> Void = {
            let title = course.enrolled ? self.unsubscribeTitle : self.subscribeTitle
            self.view?.showLoading(title: title)
            self.subscribe(to: course, delete: course.enrolled) {
                self.view?.hideLoading()
            }
        }

        let section = CourseInfoSection(.main(host: hostname, descr: descr, imageURL: imageURL, trailerAction: trailerAction, subscriptionAction: subscriptionAction, selectionAction: selectionAction, enrolled: course.enrolled), title: title, isAuthorized: isAuthorized)
        return section
    }

    private func createDetailSections(course: Course, selectionAction: @escaping (TVFocusableText) -> Void) -> [CourseInfoSection] {
        let audienceTitle = NSLocalizedString("Audience", comment: "")
        let certificateTitle = NSLocalizedString("Certificate", comment: "")
        let requirementsTitle = NSLocalizedString("Requirements", comment: "")
        let workloadTitle = NSLocalizedString("Workload", comment: "")
        let summaryTitle = NSLocalizedString("Summary", comment: "")

        let detailsParams = [audienceTitle: course.audience, certificateTitle: course.certificate, requirementsTitle: course.requirements, workloadTitle: course.workload, summaryTitle: course.summary].filter {
            $0.value != ""
        }
        let sections = detailsParams.map {
            CourseInfoSection(.text(content: $0.value, selectionAction: selectionAction), title: $0.key)
        }
        return sections
    }

    private func createInstructorsSection(selectionAction: @escaping (TVFocusableText) -> Void) -> CourseInfoSection? {
        let instructorsViewData = instructors.map {
            ItemViewData(placeholder: #imageLiteral(resourceName: "placeholderEmpty"), imageURLString: $0.avatarURL, id: $0.id, title: "\($0.lastName) \($0.firstName)") { }
        }

        guard instructorsViewData.count != 0 else { return nil }

        let instructorsTitle = NSLocalizedString("Instructors", comment: "")

        let instructorsSection = CourseInfoSection(.instructors(items: instructorsViewData), title: instructorsTitle)
        return instructorsSection
    }

    private func playIntro(intro: Video) {
        guard let viewController = view as? UIViewController else { fatalError() }

        let player = TVPlayerViewController()
            player.video = intro

        viewController.present(player, animated: true) {}
    }

    private func subscribe(to course: Course, delete: Bool = false, completion: @escaping () -> Void) {
        checkToken().then {
            [weak self]
            () -> Promise<Course> in
            guard let strongSelf = self else {
                throw CourseSubscriber.CourseSubscriptionError.error(status: "")
            }
            let subscriber = strongSelf.subscriber
            return delete ? subscriber.leave(course: course) : subscriber.join(course: course)
        }.then {
            [weak self]
            course -> Void in
            guard let strongSelf = self else { return }
            strongSelf.course?.enrolled = !delete

            if delete {
                completion()
                strongSelf.view?.dismissOnUnsubscribe()
            } else {
                strongSelf.view?.provide(sections: strongSelf.buildSections(with: course))

                completion()
                guard let viewController = strongSelf.view as? UIViewController, let course = strongSelf.course else { return }
                ScreensTransitions.moveToCourseContent(from: viewController, for: course)
            }
        }.catch {
            error in
            print("error: " + error.localizedDescription)
        }
    }
}

struct CourseInfoSection {
    let title: String
    let contentType: CourseInfoSectionType
    var isAuthorized: Bool

    init(_ contentType: CourseInfoSectionType, title: String, isAuthorized: Bool = false) {
        self.contentType = contentType
        self.title = title
        self.isAuthorized = isAuthorized
    }
}

enum CourseInfoSectionType {
    case main(host: String, descr: String, imageURL: URL?, trailerAction: (() -> Void)?, subscriptionAction: () -> Void, selectionAction: (TVFocusableText) -> Void, enrolled: Bool)
    case text(content: String, selectionAction: (TVFocusableText) -> Void)
    case instructors(items: [ItemViewData])

    var viewClass: CourseInfoSectionViewProtocol.Type {
        switch self {
        case .main:
            return MainCourseInfoSectionCell.self
        case .text:
            return DetailsCourseInfoSectionCell.self
        case .instructors:
            return InstructorsCourseInfoSectionCell.self
        }
    }
}
