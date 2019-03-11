//
//  ExploreExploreInteractor.swift
//  stepik-ios
//
//  Created by Stepik on 10/09/2018.
//  Copyright 2018 Stepik. All rights reserved.
//

import Foundation
import PromiseKit

protocol ExploreInteractorProtocol: BaseExploreInteractorProtocol {
    func doContentLoading(request: Explore.LoadContent.Request)
    func doLanguageSwitchBlockLoading(request: Explore.CheckLanguageSwitchAvailability.Request)
}

final class ExploreInteractor: BaseExploreInteractor, ExploreInteractorProtocol {
    private lazy var explorePresenter = self.presenter as? ExplorePresenterProtocol
    let contentLanguageSwitchAvailabilityService: ContentLanguageSwitchAvailabilityServiceProtocol

    init(
        presenter: ExplorePresenterProtocol,
        contentLanguageService: ContentLanguageServiceProtocol,
        networkReachabilityService: NetworkReachabilityServiceProtocol,
        languageSwitchAvailabilityService: ContentLanguageSwitchAvailabilityServiceProtocol
    ) {
        self.contentLanguageSwitchAvailabilityService = languageSwitchAvailabilityService
        super.init(
            presenter: presenter,
            contentLanguageService: contentLanguageService,
            networkReachabilityService: networkReachabilityService
        )
    }

    func doContentLoading(request: Explore.LoadContent.Request) {
        self.explorePresenter?.presentContent(
            response: .init(contentLanguage: self.contentLanguageService.globalContentLanguage)
        )
    }

    func doLanguageSwitchBlockLoading(request: Explore.CheckLanguageSwitchAvailability.Request) {
        self.explorePresenter?.presentLanguageSwitchBlock(
            response: .init(
                isHidden: !self.contentLanguageSwitchAvailabilityService
                    .shouldShowLanguageSwitchOnExplore
            )
        )
        self.contentLanguageSwitchAvailabilityService.shouldShowLanguageSwitchOnExplore = false
    }
}

extension ExploreInteractor: StoriesOutputProtocol {
    func hideStories() {
        self.explorePresenter?.presentStoriesBlock(response: .init(isHidden: true))
    }
}

extension ExploreInteractor: TagsOutputProtocol {
    func presentCourseList(type: TagCourseListType) {
        self.doFullscreenCourseListLoading(
            request: .init(
                presentationDescription: nil,
                courseListType: type
            )
        )
    }
}

extension ExploreInteractor: CourseListCollectionOutputProtocol {
    func presentCourseList(
        presentationDescription: CourseList.PresentationDescription,
        type: CollectionCourseListType
    ) {
        self.doFullscreenCourseListLoading(
            request: .init(
                presentationDescription: presentationDescription,
                courseListType: type
            )
        )
    }
}
