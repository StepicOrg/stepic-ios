import SnapKit
import UIKit

protocol TableQuizViewDelegate: AnyObject {
    func tableQuizView(_ view: TableQuizView, didSelectRow row: TableQuiz.Row)
}

extension TableQuizView {
    struct Appearance {
        let titleFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let titleTextColor = UIColor.stepikPrimaryText
    }
}

final class TableQuizView: UIView {
    let appearance: Appearance

    weak var delegate: TableQuizViewDelegate?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = self.appearance.titleFont
        label.textColor = self.appearance.titleTextColor
        return label
    }()

    private lazy var rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private var rows = [TableQuiz.Row]()

    override var intrinsicContentSize: CGSize {
        let rowsStackViewIntrinsicContentSize = self.rowsStackView
            .systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: UIView.noIntrinsicMetric, height: rowsStackViewIntrinsicContentSize.height)
    }

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }

    func set(rows: [TableQuiz.Row]) {
        if self.rows == rows {
            return
        }

        self.rows = rows

        if !self.rowsStackView.arrangedSubviews.isEmpty {
            self.rowsStackView.removeAllArrangedSubviews()
        }

        for (index, row) in rows.enumerated() {
            let rowView = TableRowView()
            rowView.shouldShowSeparator = index != rows.count - 1
            rowView.onTouchUpInside = { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.delegate?.tableQuizView(strongSelf, didSelectRow: row)
            }

            self.rowsStackView.addArrangedSubview(rowView)

            rowView.title = row.text
            rowView.subtitle = row.answers.map(\.text).joined(separator: ", ")
        }
    }
}

extension TableQuizView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
    }

    func addSubviews() {
        self.addSubview(self.rowsStackView)
    }

    func makeConstraints() {
        self.rowsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
