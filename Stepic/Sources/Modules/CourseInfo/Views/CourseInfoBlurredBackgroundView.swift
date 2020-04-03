import Nuke
import SnapKit
import UIKit

extension CourseInfoBlurredBackgroundView {
    struct Appearance {
        let imageFadeInDuration: TimeInterval = 0.15
        let placeholderImage = UIImage(named: "lesson_cover_50")
        let overlayColor = UIColor(hex6: 0x9191BC)
        let overlayAlpha: CGFloat = 0.75
    }
}

final class CourseInfoBlurredBackgroundView: UIView {
    let appearance: Appearance

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: nil)
        return blurView
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = self.appearance.overlayColor
        view.alpha = self.appearance.overlayAlpha
        return view
    }()

    init(frame: CGRect = .zero, appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()

        self.updateBlurEffect()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.performBlockIfAppearanceChanged(from: previousTraitCollection) {
            self.updateBlurEffect()
        }
    }

    func loadImage(url: URL?) {
        if let url = url {
            Nuke.loadImage(
                with: url,
                options: ImageLoadingOptions(
                    transition: ImageLoadingOptions.Transition.fadeIn(
                        duration: self.appearance.imageFadeInDuration
                    )
                ),
                into: self.imageView
            )
        } else {
            self.imageView.image = nil
        }
    }

    private func updateBlurEffect() {
        if #available(iOS 13.0, *), self.isDarkInterfaceStyle {
            self.blurView.effect = UIBlurEffect(style: .systemThickMaterialDark)
        } else {
            self.blurView.effect = UIBlurEffect(style: .dark)
        }
    }
}

extension CourseInfoBlurredBackgroundView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.imageView.image = self.appearance.placeholderImage
    }

    func addSubviews() {
        self.addSubview(self.imageView)
        self.addSubview(self.overlayView)
        self.addSubview(self.blurView)
    }

    func makeConstraints() {
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.blurView.translatesAutoresizingMaskIntoConstraints = false
        self.blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
