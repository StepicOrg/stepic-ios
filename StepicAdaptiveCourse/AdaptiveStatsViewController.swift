//
//  AdaptiveStatsViewController.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 27.07.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit
import Charts

class AdaptiveStatsViewController: UIViewController {
    enum State {
        case progress
        case achievements
        case ratings(days: Int?)
    }

    fileprivate var state: State = .progress {
        didSet {
            loadingIndicator.startAnimating()
            switch state {
            case .progress:
                statsPresenter?.reloadData(force: data == nil)
                ratingSegmentedControl.isHidden = true
                tableView.tableFooterView?.isHidden = true
                break
            case .achievements:
                achievementsPresenter?.reloadData(force: data == nil)
                ratingSegmentedControl.isHidden = true
                tableView.tableFooterView?.isHidden = true
                break
            case .ratings(let days):
                ratingsPresenter?.reloadData(days: days, force: data == nil)
                ratingSegmentedControl.isHidden = false
                tableView.tableFooterView?.isHidden = false
                allCountLabel.isHidden = true
            }
        }
    }

    var statsPresenter: AdaptiveStatsPresenter?
    var achievementsPresenter: AdaptiveAchievementsPresenter?
    var ratingsPresenter: AdaptiveRatingsPresenter?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressChart: LineChartView!
    @IBOutlet weak var currentWeekXPLabel: UILabel!
    @IBOutlet weak var bestStreakLabel: UILabel!
    @IBOutlet weak var currentLevelLabel: UILabel!
    @IBOutlet weak var allCountLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var ratingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    fileprivate var data: [Any]?
    fileprivate var scoreboardData: ScoreboardViewData?

    @IBAction func onRatingSegmentedControlValueChanged(_ sender: Any) {
        if ratingSegmentedControl.selectedSegmentIndex == 0 {
            state = .ratings(days: nil)
        } else {
            state = .ratings(days: 7)
        }
    }

    @IBAction func onSegmentedControlValueChanged(_ sender: Any) {
        let states: [Int: State] = [
            0: .progress,
            1: .achievements,
            2: .ratings(days: 7)
        ]
        state = states[segmentedControl.selectedSegmentIndex] ?? .progress
    }

    @IBAction func onCancelButtonClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        statsPresenter = AdaptiveStatsPresenter(statsManager: StatsManager.shared, ratingManager: RatingManager.shared, view: self)
        achievementsPresenter = AdaptiveAchievementsPresenter(achievementsManager: AchievementManager.shared, view: self)
        ratingsPresenter = AdaptiveRatingsPresenter(ratingsAPI: RatingsAPI(), view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTable()
        setUpChart()

        statsPresenter?.reloadStats()

        // Default state
        state = .progress
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = tableView.tableHeaderView else {
            return
        }

        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }

    func reload() {
        loadingIndicator.stopAnimating()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.reloadData()
    }

    fileprivate func valuesToDataEntries(values: [Int]) -> [ChartDataEntry] {
        var dataEntries: [ChartDataEntry] = []

        for i in 0..<values.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: Double(values[i]))
            dataEntries.append(dataEntry)
        }

        return dataEntries
    }

    fileprivate func setUpTable() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 112

        tableView.register(UINib(nibName: "ProgressTableViewCell", bundle: nil), forCellReuseIdentifier: ProgressTableViewCell.reuseId)
        tableView.register(UINib(nibName: "AchievementTableViewCell", bundle: nil), forCellReuseIdentifier: AchievementTableViewCell.reuseId)
        tableView.register(UINib(nibName: "LeaderboardTableViewCell", bundle: nil), forCellReuseIdentifier: LeaderboardTableViewCell.reuseId)
    }

    fileprivate func setUpChart() {
        progressChart.chartDescription?.enabled = false
        progressChart.isUserInteractionEnabled = false
        progressChart.setScaleEnabled(false)
        progressChart.pinchZoomEnabled = false
        progressChart.drawGridBackgroundEnabled = false
        progressChart.dragEnabled = false
        progressChart.xAxis.enabled = false
        progressChart.leftAxis.enabled = false
        progressChart.rightAxis.enabled = false
        progressChart.legend.enabled = false
    }

    fileprivate func updateDataSet(_ dataSet: LineChartDataSet) -> LineChartDataSet {
        dataSet.setColor(StepicApplicationsInfo.adaptiveMainColor)
        dataSet.mode = .horizontalBezier
        dataSet.cubicIntensity = 0.2
        dataSet.circleRadius = 4
        dataSet.circleHoleRadius = 2
        dataSet.fillColor = StepicApplicationsInfo.adaptiveMainColor
        dataSet.fillAlpha = 1.0
        dataSet.drawValuesEnabled = true
        dataSet.valueFont = UIFont.systemFont(ofSize: 10)
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.drawCirclesEnabled = true
        dataSet.setCircleColor(StepicApplicationsInfo.adaptiveMainColor)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 0)

        return dataSet
    }
}

extension AdaptiveStatsViewController: AdaptiveRatingsView {
    func setRatings(data: ScoreboardViewData) {
        scoreboardData = data
        allCountLabel.text = "\(scoreboardData?.allCount ?? 0) пользователей в рейтинге"
        allCountLabel.isHidden = false
    }

    var separatorPosition: Int? {
        guard let scoreboardData = scoreboardData else {
            return nil
        }

        switch state {
        case .ratings(_):
            for i in 0..<(scoreboardData.leaders.count - 1) {
                if scoreboardData.leaders[i].position + 1 != scoreboardData.leaders[i + 1].position {
                    return i
                }
            }
            return nil
        default:
            return nil
        }
    }
}

extension AdaptiveStatsViewController: AdaptiveAchievementsView {
    func setAchievements(records: [AchievementViewData]) {
        data = records
    }
}

extension AdaptiveStatsViewController: AdaptiveStatsView {
    func setProgress(records: [WeekProgressViewData]) {
        data = records.reversed()
    }

    func setGeneralStats(currentLevel: Int, bestStreak: Int, currentWeekXP: Int, last7DaysProgress: [Int]?) {
        currentLevelLabel.text = "\(currentLevel)"
        bestStreakLabel.text = "\(bestStreak)"
        currentWeekXPLabel.text = "\(currentWeekXP)"

        guard let last7DaysProgress = last7DaysProgress else {
            return
        }

        let dataSet = updateDataSet(LineChartDataSet(values: valuesToDataEntries(values: last7DaysProgress.reversed()), label: ""))
        let data = LineChartData(dataSet: dataSet)
        progressChart.data = data
        progressChart.data?.highlightEnabled = true
        progressChart.animate(yAxisDuration: 1.4, easingOption: .easeInOutCirc)
    }
}

extension AdaptiveStatsViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .progress, .achievements:
            return data?.count ?? 0
        case .ratings(_):
            return (scoreboardData?.leaders.count ?? 0) + (separatorPosition != nil ? 1 : 0)
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state {
        case .progress:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableViewCell.reuseId, for: indexPath) as! ProgressTableViewCell
            if let weekProgress = data?[indexPath.item] as? WeekProgressViewData {
                cell.updateInfo(expCount: weekProgress.progress, begin: weekProgress.weekBegin, end: weekProgress.weekBegin.addingTimeInterval(6 * 24 * 60 * 60), isRecord: weekProgress.isRecord)
            }
            return cell
        case .achievements:
            let cell = tableView.dequeueReusableCell(withIdentifier: AchievementTableViewCell.reuseId, for: indexPath) as! AchievementTableViewCell
            if let achievement = data?[indexPath.item] as? AchievementViewData {
                cell.updateInfo(name: achievement.name, info: achievement.info, cover: achievement.cover, isUnlocked: achievement.isUnlocked, type: achievement.type, currentProgress: achievement.currentProgress, maxProgress: achievement.maxProgress)
            }
            return cell
        case .ratings(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: LeaderboardTableViewCell.reuseId, for: indexPath) as! LeaderboardTableViewCell

            let separatorAfterIndex = (separatorPosition ?? Int.max - 1)

            if separatorAfterIndex + 1 == indexPath.item {
                cell.cellPosition = .separator
            } else {
                let dataIndex = separatorAfterIndex < indexPath.item ? indexPath.item - 1 : indexPath.item

                if let user = scoreboardData?.leaders[dataIndex] {
                    cell.cellPosition = indexPath.item == tableView.numberOfRows(inSection: indexPath.section) - 1 ? .bottom : (indexPath.item == 0 ? .top : .middle)

                    if dataIndex == separatorAfterIndex {
                        cell.cellPosition = .bottom
                    } else if dataIndex - 1 == separatorAfterIndex {
                        cell.cellPosition = .top
                    }

                    cell.updateInfo(position: user.position, username: user.name, exp: user.exp, isMe: user.me)
                }
            }
            return cell
        }
    }

}
