import SnapKit
import UIKit

protocol SettingsTableViewDelegate: SettingsInputCellDelegate, SettingsLargeInputCellDelegate { }

extension SettingsTableView {
    struct Appearance {
        var style: Style = .grouped
    }
}

final class SettingsTableView: UIView {
    let appearance: Appearance
    weak var delegate: SettingsTableViewDelegate?

    private var viewModel: SettingsTableViewModel?

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: self.appearance.style.uiStyle)
        tableView.dataSource = self
        tableView.delegate = self

        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 50.0

        tableView.register(cellClass: SettingsInputTableViewCell<TableInputTextField>.self)
        tableView.register(cellClass: SettingsLargeInputTableViewCell<TableInputTextView>.self)
        tableView.register(cellClass: SettingsRightDetailTableViewCell.self)

        tableView.register(headerFooterViewClass: SettingsTableSectionHeaderView.self)
        tableView.register(headerFooterViewClass: SettingsTableSectionFooterView.self)

        return tableView
    }()

    private lazy var inputCellGroups: [SettingsInputCellGroup] = []

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: SettingsTableViewModel) {
        self.viewModel = viewModel
        self.tableView.reloadData()

        // Create input groups for each input type
        self.inputCellGroups.removeAll()
        let flattenInputCellGroups: [String] = viewModel.sections
            .flatMap { $0.cells }
            .compactMap { cell in
                if case .input(let options) = cell.type {
                    return options.inputGroup
                }
                return nil
            }
        for group in Array(Set(flattenInputCellGroups)) {
            self.inputCellGroups.append(SettingsInputCellGroup(uniqueIdentifier: group))
        }

        // Section footers heights not being calculated properly APPS-2586.
        self.performTableViewUpdates()
    }

    // MARK: Cells initialization

    func updateInputCell(
        _ cell: SettingsInputTableViewCell<TableInputTextField>,
        viewModel: SettingsTableSectionViewModel.Cell,
        options: InputCellOptions
    ) {
        cell.uniqueIdentifier = viewModel.uniqueIdentifier
        cell.elementView.placeholder = options.placeholderText
        cell.elementView.text = options.valueText
        cell.elementView.shouldAlwaysShowPlaceholder = options.shouldAlwaysShowPlaceholder
        cell.elementView.isEnabled = options.isEnabled
        cell.delegate = self.delegate
        self.inputCellGroups.first { $0.uniqueIdentifier == options.inputGroup }?.addInputCell(cell)
    }

    func updateLargeInputCell(
        _ cell: SettingsLargeInputTableViewCell<TableInputTextView>,
        viewModel: SettingsTableSectionViewModel.Cell,
        options: LargeInputCellOptions
    ) {
        cell.elementView.placeholder = options.placeholderText
        cell.elementView.text = options.valueText
        cell.elementView.maxTextLength = options.maxLength
        cell.delegate = self.delegate
        cell.uniqueIdentifier = viewModel.uniqueIdentifier
        cell.onHeightUpdate = { [weak self] in
            self?.performTableViewUpdates()
        }
    }

    func updateRightDetailCell(
        _ cell: SettingsRightDetailTableViewCell,
        viewModel: SettingsTableSectionViewModel.Cell,
        options: RightDetailCellOptions
    ) {
        cell.elementView.title = options.titleText
        cell.accessoryType = options.accessoryType

        switch options.detailValue {
        case .label(let detailText):
            cell.elementView.detailText = detailText
        case .switch(let isOn):
            cell.elementView.detailSwitchIsOn = isOn
        }
    }

    // MARK: Private API

    private func performTableViewUpdates() {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    // MARK: Inner Types

    enum Style {
        case grouped
        /// Fallbacks to `grouped` on earlier versions.
        case insetGrouped

        fileprivate var uiStyle: UITableView.Style {
            switch self {
            case .grouped:
                return .grouped
            case .insetGrouped:
                if #available(iOS 13.0, *) {
                    return .insetGrouped
                } else {
                    return .grouped
                }
            }
        }
    }
}

extension SettingsTableView: ProgrammaticallyInitializableViewProtocol {
    func addSubviews() {
        self.addSubview(self.tableView)
    }

    func makeConstraints() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SettingsTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        self.viewModel?.sections.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel?.sections[safe: section]?.cells.count ?? 0
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let sectionViewModel = self.viewModel?.sections[safe: indexPath.section],
              let cellViewModel = sectionViewModel.cells[safe: indexPath.item] else {
            fatalError("View model is undefined")
        }

        switch cellViewModel.type {
        case .input(let options):
            let cell: SettingsInputTableViewCell<TableInputTextField> = tableView.dequeueReusableCell(for: indexPath)
            self.updateInputCell(cell, viewModel: cellViewModel, options: options)
            return cell
        case .largeInput(let options):
            let cell: SettingsLargeInputTableViewCell<TableInputTextView> = tableView.dequeueReusableCell(
                for: indexPath
            )
            self.updateLargeInputCell(cell, viewModel: cellViewModel, options: options)
            return cell
        case .rightDetail(let options):
            let cell: SettingsRightDetailTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            self.updateRightDetailCell(cell, viewModel: cellViewModel, options: options)
            return cell
        }
    }
}

extension SettingsTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = self.viewModel?.sections[safe: section]?.header?.title {
            let view: SettingsTableSectionHeaderView = tableView.dequeueReusableHeaderFooterView()
            view.title = title
            return view
        }

        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let description = self.viewModel?.sections[safe: section]?.footer?.description {
            let view: SettingsTableSectionFooterView = tableView.dequeueReusableHeaderFooterView()
            view.text = description
            return view
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionViewModel = self.viewModel?.sections[safe: indexPath.section],
              let cellViewModel = sectionViewModel.cells[safe: indexPath.item] else {
            fatalError("View model is undefined")
        }

        switch cellViewModel.type {
        case .largeInput, .rightDetail:
            return UITableView.automaticDimension
        default:
            return 44.0
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 44.0 }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        self.viewModel?.sections[safe: section]?.header?.title != nil
            ? 53.0
            : UITableView.automaticDimension
    }
}
