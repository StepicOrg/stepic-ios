//
//  SettingsViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 04.09.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

class SettingsViewController: MenuViewController, SettingsView {
    var presenter: SettingsPresenter?

    private enum SocialNetworks {
        static let vk = URL(string: "https://vk.com/rustepik")!
        static let facebook = URL(string: "https://facebook.com/stepikorg")!
        static let instagram = URL(string: "https://instagram.com/stepik.education/")!
    }

    override func viewDidLoad() {
        edgesForExtendedLayout = []

        super.viewDidLoad()
        presenter = SettingsPresenter(view: self)
        tableView.tableHeaderView = artView
        self.title = NSLocalizedString("Settings", comment: "")

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AmplitudeAnalyticsEvents.Settings.opened.send()
    }

    lazy var artView: ArtView = {
        let artView = ArtView(frame: CGRect.zero)
        artView.onVKClick = {
            AnalyticsReporter.reportEvent(
                AnalyticsEvents.Profile.Settings.socialNetworkClick,
                parameters: ["social": "vk"]
            )
            UIApplication.shared.openURL(SocialNetworks.vk)
        }

        artView.onFacebookClick = {
            AnalyticsReporter.reportEvent(
                AnalyticsEvents.Profile.Settings.socialNetworkClick,
                parameters: ["social": "facebook"]
            )
            UIApplication.shared.openURL(SocialNetworks.facebook)
        }

        artView.onInstagramClick = {
            AnalyticsReporter.reportEvent(
                AnalyticsEvents.Profile.Settings.socialNetworkClick,
                parameters: ["social": "instagram"]
            )
            UIApplication.shared.openURL(SocialNetworks.instagram)
        }
        return artView
    }()

    private func constructMenuBlock(from menuBlockID: SettingsMenuBlock) -> MenuBlock {
        switch menuBlockID {
        case .videoHeader:
            return buildTitleMenuBlock(id: menuBlockID, title: NSLocalizedString("Video", comment: ""))
        case .loadedVideoQuality:
            return buildLoadedVideoQualityBlock()
        case .onlineVideoQuality:
            return buildOnlineVideoQualityBlock()
        case .codeEditorSettingsHeader:
            return buildTitleMenuBlock(id: menuBlockID, title: NSLocalizedString("CodeEditorTitle", comment: ""))
        case .codeEditorSettings:
            return buildCodeEditorSettingsBlock()
        case .languageSettingsHeader:
            return buildTitleMenuBlock(id: menuBlockID, title: NSLocalizedString("LanguageSettingsTitle", comment: ""))
        case .contentLanguage:
            return buildContentLanguageSettingsBlock()
        case .adaptiveHeader:
            return buildTitleMenuBlock(id: menuBlockID, title: NSLocalizedString("AdaptivePreferencesTitle", comment: ""))
        case .adaptiveModeSwitch:
            return buildAdaptiveModeSwitchBlock()
        case .downloads:
            return buildDownloadsBlock()
        case .logout:
            return buildLogoutBlock()
        }
    }

    func setMenu(menuIDs: [SettingsMenuBlock]) {
        var blocks: [MenuBlock] = []
        for menuBlockID in menuIDs {
            blocks += [constructMenuBlock(from: menuBlockID)]
        }
        self.menu = Menu(blocks: blocks)
    }

    private func buildTitleMenuBlock(id: SettingsMenuBlock, title: String) -> HeaderMenuBlock {
        return HeaderMenuBlock(id: id.rawValue, title: title)
    }

    private func buildContentLanguageSettingsBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: SettingsMenuBlock.contentLanguage.rawValue, title: NSLocalizedString("ContentLanguagePreference", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.changeContentLanguageSettings()
        }

        return block
    }

    private func buildLoadedVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: SettingsMenuBlock.loadedVideoQuality.rawValue, title: NSLocalizedString("LoadingVideoQualityPreference", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.changeVideoQuality(action: .downloading)
        }

        return block
    }

    private func buildOnlineVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: SettingsMenuBlock.onlineVideoQuality.rawValue, title: NSLocalizedString("WatchingVideoQualityPreference", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.changeVideoQuality(action: .watching)
        }

        return block
    }

    private func buildDownloadsBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: SettingsMenuBlock.downloads.rawValue, title: NSLocalizedString("Downloads", comment: ""))

        block.onTouch = { [weak self] in
            self?.openDownloads()
        }

        return block
    }

    private func buildAdaptiveModeSwitchBlock() -> SwitchMenuBlock {
        let block = SwitchMenuBlock(id: SettingsMenuBlock.adaptiveModeSwitch.rawValue, title: NSLocalizedString("UseAdaptiveModePreference", comment: ""), isOn: AdaptiveStorageManager.shared.isAdaptiveModeEnabled)

        block.onSwitch = {
            [weak self]
            isOn in
            self?.presenter?.changeAdaptiveModeEnabled(to: isOn)
        }

        return block
    }

    private func buildCodeEditorSettingsBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: SettingsMenuBlock.codeEditorSettings.rawValue, title: NSLocalizedString("CodeEditorSettingsTitle", comment: ""))

        block.onTouch = {
            [weak self] in
            self?.changeCodeEditorSettings()
        }

        return block
    }

    private func buildLogoutBlock() -> TransitionMenuBlock {
        let block: TransitionMenuBlock = TransitionMenuBlock(id: SettingsMenuBlock.logout.rawValue, title: NSLocalizedString("Logout", comment: ""))

        block.titleColor = UIColor(red: 200 / 255.0, green: 40 / 255.0, blue: 80 / 255.0, alpha: 1)
        block.onTouch = {
            [weak self] in
            self?.presenter?.logout()
        }

        return block
    }

    func changeVideoQuality(action: VideoQualityChoiceAction) {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "VideoQualityTableViewController", storyboardName: "Profile") as? VideoQualityTableViewController else {
            return
        }

        vc.action = action

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func changeContentLanguageSettings() {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "LanguageSettingsViewController", storyboardName: "Profile") as? LanguageSettingsViewController else {
            return
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func changeCodeEditorSettings() {
        let assembly = CodeEditorSettingsLegacyAssembly()
        self.navigationController?.pushViewController(assembly.makeModule(), animated: true)
    }

    func openDownloads() {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "DownloadsViewController", storyboardName: "Main") as? DownloadsViewController else {
            return
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.layoutTableHeaderView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.tableView.layoutTableHeaderView()
    }

    func presentAuth() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: false)
            RoutingManager.auth.routeFrom(controller: navigationController, success: nil, cancel: nil)
        }
    }
}
