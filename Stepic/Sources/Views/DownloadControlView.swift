import SnapKit
import UIKit

extension DownloadControlView {
    struct Appearance {
        let circleWidth: CGFloat = 2.8

        let downloadingCircleColor = UIColor.stepikGreenFixed
        let downloadingBackgroundColor = UIColor.stepikAccentAlpha25

        let pendingCircleColor = UIColor.stepikAccent

        let iconImageTintColor = UIColor.stepikAccent
    }
}

final class DownloadControlView: UIControl {
    enum Animation {
        static let pendingDuration: TimeInterval = 1.0
    }

    let appearance: Appearance

    var actionState: ActionState {
        didSet {
            self.updateVisibility()
            self.updateIcon()

            switch self.actionState {
            case .downloading(let progress):
                self.updateDownloadingProgress(progress)
            default:
                break
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            self.alpha = self.isEnabled ? 1.0 : 0.4
        }
    }

    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.5 : 1.0
        }
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = self.appearance.iconImageTintColor
        return imageView
    }()

    private lazy var pendingCircleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = self.appearance.pendingCircleColor.cgColor
        layer.lineWidth = self.appearance.circleWidth
        return layer
    }()

    private lazy var downloadingCircleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = self.appearance.downloadingCircleColor.cgColor
        layer.lineWidth = self.appearance.circleWidth
        layer.strokeEnd = 0
        return layer
    }()

    private lazy var downloadingBackgroundCircleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.strokeColor = self.appearance.downloadingBackgroundColor.cgColor
        layer.lineWidth = self.appearance.circleWidth
        return layer
    }()

    init(
        frame: CGRect = .zero,
        initialState: ActionState = .readyToDownloading,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        self.actionState = initialState
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

        self.updatePendingCirclePath()
        self.updateDownloadingCirclePath()
    }

    private func updatePendingCirclePath() {
        let pendingCirclePath = UIBezierPath()
        pendingCirclePath.addArc(
            withCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY),
            radius: self.bounds.width / 2 - self.appearance.circleWidth,
            startAngle: 0,
            endAngle: 7 * .pi / 4,
            clockwise: true
        )
        self.pendingCircleLayer.path = pendingCirclePath.cgPath
        self.pendingCircleLayer.frame = self.bounds
    }

    private func addPendingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.byValue = 2 * Float.pi
        rotation.duration = Animation.pendingDuration
        rotation.repeatCount = .infinity
        // Prevents CABasicAnimation object being destroyed APPS-2587.
        rotation.isRemovedOnCompletion = false

        self.pendingCircleLayer.add(rotation, forKey: "circleRotation")
    }

    private func updateDownloadingCirclePath() {
        let downloadingCirclePath = UIBezierPath()
        downloadingCirclePath.addArc(
            withCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY),
            radius: self.bounds.width / 2 - self.appearance.circleWidth,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        self.downloadingBackgroundCircleLayer.path = downloadingCirclePath.cgPath
        self.downloadingBackgroundCircleLayer.frame = self.bounds

        self.downloadingCircleLayer.path = downloadingCirclePath.cgPath
        self.downloadingBackgroundCircleLayer.frame = self.bounds
    }

    private func updateDownloadingProgress(_ progress: Float) {
        self.downloadingCircleLayer.strokeEnd = CGFloat(progress)
    }

    private func updateVisibility() {
        switch self.actionState {
        case .downloading:
            self.downloadingBackgroundCircleLayer.isHidden = false
            self.downloadingCircleLayer.isHidden = false
            self.pendingCircleLayer.isHidden = true
        case .pending:
            self.downloadingBackgroundCircleLayer.isHidden = true
            self.downloadingCircleLayer.isHidden = true
            self.pendingCircleLayer.isHidden = false
        default:
            self.downloadingBackgroundCircleLayer.isHidden = true
            self.downloadingCircleLayer.isHidden = true
            self.pendingCircleLayer.isHidden = true
        }
    }

    private func updateIcon() {
        var icon: UIImage?
        switch self.actionState {
        case .readyToRemoving:
            icon = UIImage(named: "download-button-remove")
        case .downloading:
            icon = UIImage(named: "download-button-cancel")
        case .readyToDownloading:
            icon = UIImage(named: "download-button-start")
        case .pending:
            icon = nil
        }
        self.iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
    }

    enum ActionState {
        case readyToDownloading
        case pending
        case downloading(progress: Float)
        case readyToRemoving
    }
}

extension DownloadControlView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.updateVisibility()
        self.updateIcon()

        if case .downloading(let progress) = self.actionState {
            self.updateDownloadingProgress(progress)
        }
    }

    func addSubviews() {
        self.addSubview(self.iconImageView)

        self.layer.addSublayer(self.pendingCircleLayer)
        self.addPendingAnimation()

        self.layer.addSublayer(self.downloadingBackgroundCircleLayer)
        self.layer.addSublayer(self.downloadingCircleLayer)
    }

    func makeConstraints() {
        self.iconImageView.translatesAutoresizingMaskIntoConstraints = false
        self.iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
