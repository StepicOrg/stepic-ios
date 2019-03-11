import SnapKit
import UIKit

extension CourseInfoTabInfoInstructorView {
    struct Appearance {
        let imageFadeInDuration: TimeInterval = 0.15
        let imageViewSize = CGSize(width: 30, height: 30)
        let imageViewCornerRadius: CGFloat = 5

        let titleLabelInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        let titleLabelFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let titleLabelTextColor = UIColor.mainDark

        let descriptionLabelInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        let descriptionLabelFont = UIFont.systemFont(ofSize: 12, weight: .light)
        let descriptionLabelTextColor = UIColor.mainDark
    }
}

final class CourseInfoTabInfoInstructorView: UIView {
    let appearance: Appearance

    var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }

    var summary: String? {
        didSet {
            self.descriptionLabel.setTextWithHTMLString(self.summary ?? "")
            self.updateDescriptionLabelTopConstraint()
        }
    }

    var avatarImageURL: URL? {
        didSet {
            if let url = self.avatarImageURL {
                self.imageView.set(with: url)
            }
        }
    }

    private lazy var imageView: AvatarImageView = {
        let view = AvatarImageView(frame: .zero)
        view.shape = .rectangle(cornerRadius: self.appearance.imageViewCornerRadius)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = self.appearance.titleLabelFont
        label.textColor = self.appearance.titleLabelTextColor
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = self.appearance.descriptionLabelFont
        label.textColor = self.appearance.descriptionLabelTextColor
        return label
    }()

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

    private func updateDescriptionLabelTopConstraint() {
        self.descriptionLabel.snp.updateConstraints { make in
            make.top
                .equalTo(self.imageView.snp.bottom)
                .offset(
                    self.descriptionLabel.text?.isEmpty ?? true
                        ? 0
                        : self.appearance.descriptionLabelInsets.top
                )
        }
    }
}

extension CourseInfoTabInfoInstructorView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = .white
    }

    func addSubviews() {
        self.addSubview(self.imageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
    }

    func makeConstraints() {
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.snp.makeConstraints { make in
            make.size.equalTo(self.appearance.imageViewSize)
            make.leading.top.equalToSuperview()
        }

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(self.imageView.snp.centerY)
            make.leading
                .equalTo(self.imageView.snp.trailing)
                .offset(self.appearance.titleLabelInsets.left)
        }

        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionLabel.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalTo(self.imageView.snp.leading)
            make.top
                .equalTo(self.imageView.snp.bottom)
                .offset(self.appearance.descriptionLabelInsets.top)
        }
    }
}
