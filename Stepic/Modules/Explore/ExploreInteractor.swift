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
    func loadLanguageSwitchBlock(request: Explore.CheckLanguageSwitchAvailability.Request)
}

final class ExploreInteractor: BaseExploreInteractor, ExploreInteractorProtocol {
    lazy var explorePresenter = self.presenter as? ExplorePresenterProtocol
    let contentLanguageSwitchAvailabilityService: ContentLanguageSwitchAvailabilityServiceProtocol

    init(
        presenter: ExplorePresenterProtocol,
        contentLanguageService: ContentLanguageServiceProtocol,
        languageSwitchAvailabilityService: ContentLanguageSwitchAvailabilityServiceProtocol
    ) {
        self.contentLanguageSwitchAvailabilityService = languageSwitchAvailabilityService
        super.init(presenter: presenter, contentLanguageService: contentLanguageService)
    }

    func loadLanguageSwitchBlock(request: Explore.CheckLanguageSwitchAvailability.Request) {
        self.explorePresenter?.presentLanguageSwitchBlock(
            response: .init(
                isHidden: !self.contentLanguageSwitchAvailabilityService
                    .shouldShowLanguageSwitchOnExplore
            )
        )
        self.contentLanguageSwitchAvailabilityService.shouldShowLanguageSwitchOnExplore = false
    }
}
