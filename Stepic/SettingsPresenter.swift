//
//  SettingsPresenter.swift
//  Stepic
//
//  Created by Ostrenkiy on 04.09.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

protocol SettingsView: class {
    func setMenu(menu: Menu)
    func changeVideoQuality(action: VideoQualityChoiceAction)
}

class SettingsPresenter {
    weak var view: SettingsView?
    var menu: Menu = Menu(blocks: [])

    init(view: SettingsView) {
        self.view = view
        self.menu = buildSettingsMenu()
        view.setMenu(menu: self.menu)
    }

    private func buildSettingsMenu() -> Menu {
        let blocks = [
            buildTitleMenuBlock(id: videoHeaderBlockId, title: "Video"),
            buildOnlyWifiSwitchBlock(),
            buildLoadedVideoQualityBlock(),
            buildOnlineVideoQualityBlock()
        ]
        return Menu(blocks: blocks)
    }

    // MARK: - Menu blocks

    private let videoHeaderBlockId = "video_header"
    private let onlyWifiSwitchBlockId = "only_wifi_switch"
    private let loadedVideoQualityBlockId = "loaded_video_quality"
    private let onlineVideoQualityBlockId = "online_video_quality"

    private func buildTitleMenuBlock(id: String, title: String) -> HeaderMenuBlock {
        return HeaderMenuBlock(id: id, title: title)
    }

    private func buildLoadedVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: loadedVideoQualityBlockId, title: "Downloaded video quality")

        block.onTouch = {
            [weak self] in
            self?.view?.changeVideoQuality(action: .downloading)
        }

        return block
    }

    private func buildOnlineVideoQualityBlock() -> TransitionMenuBlock {
        let block = TransitionMenuBlock(id: onlineVideoQualityBlockId, title: "Online video quality")

        block.onTouch = {
            [weak self] in
            self?.view?.changeVideoQuality(action: .watching)
        }

        return block
    }

    private func buildOnlyWifiSwitchBlock() -> SwitchMenuBlock {
        let block = SwitchMenuBlock(id: onlyWifiSwitchBlockId, title: "Only wi-fi download", isOn: !ConnectionHelper.shared.reachableOnWWAN)

        block.onSwitch = {
            isOn in
            ConnectionHelper.shared.reachableOnWWAN = !isOn
        }

        return block
    }

}
