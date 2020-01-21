//
//  StepikPlaceholderStyle+Placeholders.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 20.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

extension StepikPlaceholder.Style {
    static let noConnection = StepikPlaceholderStyle(
        id: "noConnection",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-noconnection"), scale: 0.49),
        text: NSLocalizedString("PlaceholderNoConnectionText", comment: ""),
        buttonTitle: NSLocalizedString("PlaceholderNoConnectionButton", comment: "")
    )
    static let login = StepikPlaceholderStyle(
        id: "login",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-login"), scale: 0.59),
        text: NSLocalizedString("PlaceholderLoginText", comment: ""),
        buttonTitle: NSLocalizedString("PlaceholderLoginButton", comment: "")
    )
    static let noConnectionQuiz = StepikPlaceholderStyle(
        id: "noConnectionQuiz",
        image: nil,
        text: NSLocalizedString("ConnectionErrorText", comment: ""),
        buttonTitle: NSLocalizedString("TryAgain", comment: "")
    )
    static let adaptiveCoursePassed = StepikPlaceholderStyle(
        id: "adaptiveCoursePassed",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("NoRecommendations", comment: ""),
        buttonTitle: nil
    )
    static let refreshStories = StepikPlaceholderStyle(
        id: "refreshStories",
        image: nil,
        text: "",
        buttonTitle: NSLocalizedString("LoadStories", comment: "")
    )

    // MARK: - Empty styles -

    static let empty = StepikPlaceholderStyle(
        id: "empty",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("PlaceholderEmptyText", comment: ""),
        buttonTitle: NSLocalizedString("PlaceholderEmptyButton", comment: "")
    )
    static let emptyDownloads = StepikPlaceholderStyle(
        id: "emptyDownloads",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-downloads"), scale: 0.46),
        text: NSLocalizedString("PlaceholderEmptyDownloadsText", comment: ""),
        buttonTitle: nil
    )
    static let emptyNotifications = StepikPlaceholderStyle(
        id: "emptyNotifications",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-notifications"), scale: 0.48),
        text: NSLocalizedString("PlaceholderEmptyNotificationsText", comment: ""),
        buttonTitle: nil
    )
    static let emptyNotificationsLoading = StepikPlaceholderStyle(
        id: "emptyNotificationsLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-notifications"), scale: 0.48),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
    static let emptySearch = StepikPlaceholderStyle(
        id: "emptySearch",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-search"), scale: 0.49),
        text: NSLocalizedString("PlaceholderEmptySearchText", comment: ""),
        buttonTitle: nil
    )
    static let emptyCertificatesMe = StepikPlaceholderStyle(
        id: "emptyCertificates",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("EmptyCertificatesTitle", comment: ""),
        buttonTitle: NSLocalizedString("ChooseCourse", comment: "")
    )
    static let emptyCertificatesOther = StepikPlaceholderStyle(
        id: "emptyCertificates",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("EmptyCertificatesTitle", comment: ""),
        buttonTitle: nil
    )
    static let emptyCertificatesLoading = StepikPlaceholderStyle(
        id: "emptyCertificatesLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
    static let emptyDiscussions = StepikPlaceholderStyle(
        id: "emptyDiscussions",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("PlaceholderNoDiscussionsTitle", comment: ""),
        buttonTitle: NSLocalizedString("PlaceholderNoDiscussionsButtonTitle", comment: "")
    )
    static let emptyDiscussionsLoading = StepikPlaceholderStyle(
        id: "emptyDiscussionsLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
    static let emptyProfileLoading = StepikPlaceholderStyle(
        id: "emptyProfileLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
    static let emptySections = StepikPlaceholderStyle(
        id: "emptySections",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("EmptyTitle", comment: ""),
        buttonTitle: nil
    )
    static let emptySectionsLoading = StepikPlaceholderStyle(
        id: "emptySectionsLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
    static let emptyUnits = StepikPlaceholderStyle(
        id: "emptyUnits",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("PullToRefreshUnitsTitle", comment: ""),
        buttonTitle: nil
    )
    static let emptyUnitsLoading = StepikPlaceholderStyle(
        id: "emptyUnitsLoading",
        image: PlaceholderImage(image: #imageLiteral(resourceName: "new-empty-empty"), scale: 0.99),
        text: NSLocalizedString("Refreshing", comment: ""),
        buttonTitle: nil
    )
}

extension StepikPlaceholder.Style {
    static var stepikStyledPlaceholders: [StepikPlaceholderStyle] {
        [
            .empty,
            .noConnection,
            .login,
            .emptyDownloads,
            .emptyNotifications,
            .emptySearch,
            .emptyCertificatesMe,
            .emptyCertificatesOther,
            .emptyDiscussions,
            .emptyProfileLoading,
            .emptySections,
            .emptyUnits
        ]
    }
}
