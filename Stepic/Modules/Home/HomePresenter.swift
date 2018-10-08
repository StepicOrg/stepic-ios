//
//  HomeHomePresenter.swift
//  stepik-ios
//
//  Created by Vladislav Kiryukhin on 17/09/2018.
//  Copyright 2018 Stepik. All rights reserved.
//

import UIKit

protocol HomePresenterProtocol: BaseExplorePresenterProtocol {
    func presentStreakActivity(response: Home.LoadStreak.Response)
    func presentContent(response: Home.LoadContent.Response)
    func presentCourseListState(response: Home.RefreshCourseList.Response)
}

final class HomePresenter: BaseExplorePresenter, HomePresenterProtocol {
    lazy var homeViewController = self.viewController as? HomeViewControllerProtocol

    func presentStreakActivity(response: Home.LoadStreak.Response) {
        var viewModel: Home.LoadStreak.ViewModel

        switch response.result {
        case .hidden:
            viewModel = .init(result: .hidden)
        case .success(let currentStreak, let needsToSolveToday):
            if currentStreak > 0 {
                viewModel = .init(
                    result: .visible(
                        message: self.makeStreakActivityMessage(
                            days: currentStreak,
                            needsToSolveToday: needsToSolveToday
                        ),
                        streak: currentStreak
                    )
                )
            } else {
                viewModel = .init(result: .hidden)
            }
        }

        self.homeViewController?.displayStreakInfo(viewModel: viewModel)
    }

    func presentContent(response: Home.LoadContent.Response) {
        self.homeViewController?.displayContent(
            viewModel: .init(
                isAuthorized: response.isAuthorized,
                contentLanguage: response.contentLanguage
            )
        )
    }

    func presentCourseListState(response: Home.RefreshCourseList.Response) {
        self.homeViewController?.displayCourseListState(
            viewModel: .init(
                module: response.module,
                result: response.result
            )
        )
    }

    private func makeStreakActivityMessage(days: Int, needsToSolveToday: Bool) -> String {
        let pluralizedDaysCnt = StringHelper.pluralize(
            number: days,
            forms: [
                NSLocalizedString("days1", comment: ""),
                NSLocalizedString("days234", comment: ""),
                NSLocalizedString("days567890", comment: "")
            ]
        )
        var countText = String(
            format: NSLocalizedString("SolveStreaksDaysCount", comment: ""),
            "\(days)",
            "\(pluralizedDaysCnt)"
        )

        if needsToSolveToday {
            countText += "\n\(NSLocalizedString("SolveSomethingToday", comment: ""))"
        }

        return countText
    }
}
