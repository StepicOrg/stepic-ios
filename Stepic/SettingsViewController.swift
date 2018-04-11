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

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = SettingsPresenter(view: self)
        tableView.tableHeaderView = artView
        self.title = NSLocalizedString("Settings", comment: "")

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
    }

    lazy var artView: ArtView = {
        let artView = ArtView(frame: CGRect.zero)
        artView.art = Images.arts.customizeLearningProcess
        if #available(iOS 11.0, *) {
            artView.width = UIScreen.main.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right
        } else {
            artView.width = UIScreen.main.bounds.width
        }

        artView.frame.size = artView.systemLayoutSizeFitting(CGSize(width: artView.width, height: artView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height))
        artView.onTap = {
            AnalyticsReporter.reportEvent(AnalyticsEvents.Profile.Settings.clickBanner)
        }
        return artView
    }()

    func setMenu(menu: Menu) {
        self.menu = menu
    }

    func changeVideoQuality(action: VideoQualityChoiceAction) {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "VideoQualityTableViewController", storyboardName: "Profile") as? VideoQualityTableViewController else {
            return
        }

        vc.action = action

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func changeCodeEditorSettings() {
        guard let vc = ControllerHelper.instantiateViewController(identifier: "CodeEditorSettings", storyboardName: "Profile") as? CodeEditorSettingsViewController else {
            return
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if #available(iOS 11.0, *) {
            artView.width = size.width - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        } else {
            artView.width = size.width
        }
        artView.frame.size = artView.systemLayoutSizeFitting(CGSize(width: artView.width, height: artView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height))
    }
}
