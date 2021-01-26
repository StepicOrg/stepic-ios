//
//  StoriesAssembly.swift
//  stepik-stories
//
//  Created by Ostrenkiy on 06.08.2018.
//  Copyright © 2018 Ostrenkiy. All rights reserved.
//

import UIKit

final class StoriesAssembly: Assembly {
    weak var moduleOutput: StoriesOutputProtocol?

    init(output: StoriesOutputProtocol?) {
        self.moduleOutput = output
    }

    func makeModule() -> UIViewController {
        let viewController = StoriesViewController()
        let presenter = StoriesPresenter(
            view: viewController,
            storyTemplatesNetworkService: StoryTemplatesNetworkService(storyTemplatesAPI: StoryTemplatesAPI()),
            contentLanguageService: ContentLanguageService(),
            userAccountService: UserAccountService(),
            personalOffersService: PersonalOffersService(
                storageRecordsNetworkService: StorageRecordsNetworkService(storageRecordsAPI: StorageRecordsAPI())
            )
        )
        presenter.moduleOutput = self.moduleOutput
        viewController.presenter = presenter

        return viewController
    }
}
