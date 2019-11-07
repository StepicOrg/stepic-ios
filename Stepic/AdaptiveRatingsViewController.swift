//
//  AdaptiveRatingsViewController.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 23.01.2018.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

final class AdaptiveRatingsViewController: UIViewController {
    enum State {
        case empty(message: String)
        case error(message: String)
        case loading
        case normal(message: String?)
    }

    private var state: State = .loading {
        didSet {
            switch state {
            case .loading:
                data = nil
                tableView.reloadData()
                loadingIndicator.startAnimating()
                allCountLabel.isHidden = true
            case .empty(let message), .error(let message):
                loadingIndicator.stopAnimating()
                allCountLabel.text = message
                allCountLabel.isHidden = false
            case .normal(let message):
                loadingIndicator.stopAnimating()
                tableView.reloadData()
                if let message = message {
                    allCountLabel.text = message
                    allCountLabel.isHidden = false
                } else {
                    allCountLabel.isHidden = true
                }
            }
        }
    }

    var presenter: AdaptiveRatingsPresenter?
    var daysCount: Int? = 1

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var allCountLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var ratingSegmentedControl: UISegmentedControl!

    private var data: [Any]?

    @IBAction func onRatingSegmentedControlValueChanged(_ sender: Any) {
        let sections: [Int: Int?] = [
            0: nil,
            1: 7,
            2: 1
        ]
        daysCount = sections[ratingSegmentedControl.selectedSegmentIndex] ?? 1
        state = .loading
        presenter?.reloadData(days: daysCount, force: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        colorize()
        localize()

        setUpTable()
        presenter?.reloadData(days: daysCount, force: true)

        state = .loading

        presenter?.sendOpenedAnalytics()
    }

    private func colorize() {
        loadingIndicator.color = UIColor.mainDark
        ratingSegmentedControl.tintColor = UIColor.mainDark
    }

    private func localize() {
        ratingSegmentedControl.setTitle(NSLocalizedString("AdaptiveAllTime", comment: ""), forSegmentAt: 0)
        ratingSegmentedControl.setTitle(NSLocalizedString("Adaptive7Days", comment: ""), forSegmentAt: 1)
        ratingSegmentedControl.setTitle(NSLocalizedString("AdaptiveToday", comment: ""), forSegmentAt: 2)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = tableView.tableHeaderView else {
            return
        }

        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }

    func reload() {
        if data == nil {
            state = .empty(message: NSLocalizedString("AdaptiveProgressWeeksEmpty", comment: ""))
        } else {
            switch state {
            case .normal(let message):
                state = .normal(message: message)
            default:
                state = .normal(message: nil)
            }
        }
    }

    private func setUpTable() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112

        tableView.register(UINib(nibName: "LeaderboardTableViewCell", bundle: nil), forCellReuseIdentifier: LeaderboardTableViewCell.reuseId)

        self.tableView.contentInsetAdjustmentBehavior = .never
    }
}

extension AdaptiveRatingsViewController: AdaptiveRatingsView {
    func setRatings(data: ScoreboardViewData) {
        self.data = data.leaders

        let pluralizedString = StringHelper.pluralize(number: data.allCount, forms: [
            NSLocalizedString("AdaptiveRatingFooterText1", comment: ""),
            NSLocalizedString("AdaptiveRatingFooterText234", comment: ""),
            NSLocalizedString("AdaptiveRatingFooterText567890", comment: "")
        ])
        state = .normal(message: String(format: pluralizedString, "\(data.allCount)"))
    }

    func showError() {
        state = .error(message: NSLocalizedString("AdaptiveRatingLoadError", comment: ""))
    }

    var separatorPosition: Int? {
        guard let data = data as? [RatingViewData] else {
            return nil
        }

        for i in 0..<max(0, data.count - 1) {
            if data[i].position + 1 != data[i + 1].position {
                return i
            }
        }
        return nil
    }
}

extension AdaptiveRatingsViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (data?.count ?? 0) + (separatorPosition != nil ? 1 : 0)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LeaderboardTableViewCell.reuseId, for: indexPath) as! LeaderboardTableViewCell

        let separatorAfterIndex = (separatorPosition ?? Int.max - 1)

        if separatorAfterIndex + 1 == indexPath.item {
            cell.isSeparator = true
        } else {
            let dataIndex = separatorAfterIndex < indexPath.item ? indexPath.item - 1 : indexPath.item

            if let user = data?[dataIndex] as? RatingViewData {
                cell.updateInfo(position: user.position, username: user.name, exp: user.exp, isMe: user.me)
            }
        }
        return cell
    }
}
