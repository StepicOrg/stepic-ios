//
//  PersonalDeadlineEditScheduleViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 30.05.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation
import UIKit
import ActionSheetPicker_3_0

class PersonalDeadlineEditScheduleViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: FullHeightTableView!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    var course: Course?
    var sectionDeadlinesData: [SectionDeadlineData] = []
    var onSavePressed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.constrainWidth("\(UIScreen.main.bounds.width - 80)")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PersonalDeadlineTableViewCell", bundle: nil), forCellReuseIdentifier: "PersonalDeadlineTableViewCell")
        initSectionDeadlinesData()
        tableView.reloadData()
        saveButton.setRoundedCorners(cornerRadius: 8, borderWidth: 1, borderColor: UIColor.lightBlue)
        localize()
    }

    private func localize() {
        titleLabel.text = NSLocalizedString("EditSchedule", comment: "")
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        saveButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
    }

    private func initSectionDeadlinesData() {
        guard let course = course else {
            return
        }
        sectionDeadlinesData = []
        for section in course.sections {
            if let sectionDeadline: SectionDeadline = course.sectionDeadlines?.first(where: { $0.section == section.id }) {
                sectionDeadlinesData += [SectionDeadlineData(section: section, deadline: sectionDeadline.deadlineDate)]
            }
        }
    }

    @IBAction func savePressed(_ sender: Any) {
        guard let course = course else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        AnalyticsReporter.reportEvent(AnalyticsEvents.PersonalDeadlines.EditSchedule.Time.saved)
        let newDeadlines = sectionDeadlinesData.map { $0.sectionDeadline }
        SVProgressHUD.show()
        PersonalDeadlineManager.shared.changeDeadline(for: course, newDeadlines: newDeadlines).done { [weak self] _ in
            SVProgressHUD.dismiss()
            self?.onSavePressed?()
            self?.dismiss(animated: true, completion: nil)
        }.catch {
            _ in
            SVProgressHUD.showError(withStatus: nil)
        }
    }

    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension PersonalDeadlineEditScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AnalyticsReporter.reportEvent(AnalyticsEvents.PersonalDeadlines.EditSchedule.Time.opened)
        let approximateYearInSeconds: Double = 60 * 60 * 24 * 30 * 365
        ActionSheetDatePicker.show(withTitle: NSLocalizedString("SelectTimeTitle", comment: ""), datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: sectionDeadlinesData[indexPath.row].deadline, minimumDate: Date(), maximumDate: Date().addingTimeInterval(approximateYearInSeconds), doneBlock: {
            [weak self]
            _, value, _ in
            guard let date = value as? Date else {
                return
            }
            self?.tableView.deselectRow(at: indexPath, animated: true)
            self?.sectionDeadlinesData[indexPath.row].deadline = date
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }, cancel: {
            [weak self]
            _ in
            AnalyticsReporter.reportEvent(AnalyticsEvents.PersonalDeadlines.EditSchedule.Time.closed)
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }, origin: tableView.cellForRow(at: indexPath))
    }
}

extension PersonalDeadlineEditScheduleViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return course?.sections.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalDeadlineTableViewCell", for: indexPath) as? PersonalDeadlineTableViewCell else {
            return UITableViewCell()
        }

        cell.initWith(data: sectionDeadlinesData[indexPath.row])
        return cell
    }
}

struct SectionDeadlineData {
    var title: String
    var sectionID: Int
    var deadline: Date

    init(section: Section, deadline: Date) {
        self.title = section.title
        self.sectionID = section.id
        self.deadline = deadline
    }

    var sectionDeadline: SectionDeadline {
        return SectionDeadline(section: sectionID, deadlineDate: deadline)
    }
}
