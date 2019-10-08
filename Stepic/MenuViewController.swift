//
//  MenuViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 30.08.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import SnapKit

class MenuViewController: UIViewController {

    let tableView: StepikTableView = StepikTableView()

    var interfaceManager: MenuUIManager?
    var menu: Menu? {
        didSet {
            menu?.delegate = self
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalTo(view) }

        tableView.separatorStyle = .none

        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self

        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableView.automaticDimension
        interfaceManager = MenuUIManager(tableView: tableView)
        tableView.contentInsetAdjustmentBehavior = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menu?.willAppear()
    }
}

extension MenuViewController: MenuDelegate {
    func getMenuIndexPath(from index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }

    func update(at index: Int) {
        tableView.reloadRows(at: [getMenuIndexPath(from: index)], with: .automatic)
    }

    func insert(at index: Int) {
        tableView.insertRows(at: [getMenuIndexPath(from: index)], with: .automatic)
    }

    func remove(at index: Int) {
        interfaceManager?.prepareToRemove(at: getMenuIndexPath(from: index))
        tableView.deleteRows(at: [getMenuIndexPath(from: index)], with: .automatic)
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let block = menu?.blocks[indexPath.row] {
            interfaceManager?.didSelect(block: block, indexPath: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let interfaceManager = interfaceManager else {
            return false
        }

        if let block = menu?.blocks[indexPath.row] {
            return interfaceManager.shouldSelect(block: block, indexPath: indexPath)
        } else {
            return false
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return menu != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu?.blocks.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let block = menu?.blocks[indexPath.row], let interfaceManager = interfaceManager else {
            return UITableViewCell()
        }
        return interfaceManager.getCell(forblock: block, indexPath: indexPath)
    }
}
