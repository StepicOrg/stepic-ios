import SnapKit
import UIKit

class StyledNavigationController: UINavigationController {
    enum Appearance {
        static let backgroundColor = UIColor.mainLight
        static let tintColor = UIColor.mainDark

        static let titleFont = UIFont.systemFont(ofSize: 17, weight: .regular)

        static let shadowViewColor = UIColor.lightGray
        static let shadowViewHeight: CGFloat = 0.5

        static let statusBarStyle = UIStatusBarStyle.dark
    }

    struct NavigationBarAppearanceState {
        var shadowViewAlpha: CGFloat
        var backgroundColor: UIColor
        var textColor: UIColor
        var tintColor: UIColor
        var statusBarStyle: UIStatusBarStyle

        init(
            shadowViewAlpha: CGFloat = 1.0,
            backgroundColor: UIColor = StyledNavigationController.Appearance.backgroundColor,
            textColor: UIColor = StyledNavigationController.Appearance.tintColor,
            tintColor: UIColor = StyledNavigationController.Appearance.tintColor,
            statusBarStyle: UIStatusBarStyle = StyledNavigationController.Appearance.statusBarStyle
        ) {
            self.shadowViewAlpha = shadowViewAlpha
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.tintColor = tintColor
            self.statusBarStyle = statusBarStyle
        }
    }

    override var delegate: UINavigationControllerDelegate? {
        didSet {
            if self.delegate !== self {
                fatalError("To set a delegate use `addDelegate(_:)`")
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.statusBarStyle
    }

    private lazy var statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)

    private var statusBarStyle: UIStatusBarStyle = StyledNavigationController.Appearance.statusBarStyle {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    private lazy var shadowView = UIView()
    private var shadowViewLeadingConstraint: Constraint?
    private var shadowViewTrailingConstraint: Constraint?

    private var lastAction = UINavigationController.Operation.none

    private var navigationBarAppearanceForController: [Int: NavigationBarAppearanceState] = [:]

    // swiftlint:disable:next weak_delegate
    private var multicastDelegate = MulticastDelegate<UINavigationControllerDelegate>()

    // MARK: ViewController lifecycle & base methods

    override func viewDidLoad() {
        self.delegate = self
        super.viewDidLoad()
        self.setupAppearance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.statusBarView.frame = UIApplication.shared.statusBarFrame
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.navigationBar.layoutIfNeeded()
                strongSelf.statusBarView.frame = UIApplication.shared.statusBarFrame
            },
            completion: nil
        )
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        self.lastAction = .pop
        return super.popViewController(animated: animated)
    }

    // swiftlint:disable:next discouraged_optional_collection
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        self.lastAction = .pop
        return super.popToRootViewController(animated: animated)
    }

    // swiftlint:disable:next discouraged_optional_collection
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        self.lastAction = .pop
        return super.popToViewController(viewController, animated: animated)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.lastAction = .push
        super.pushViewController(viewController, animated: animated)
    }

    // MARK: Public API

    /// Remove title for "Back" button on top controller
    func removeBackButtonTitleForTopController() {
        // View controller before last in stack
        guard let parentViewController = self.viewControllers.dropLast().last else {
            return
        }

        parentViewController.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
    }

    /// Change color of navigation bar & status bar background
    func changeBackgroundColor(_ color: UIColor, sender: UIViewController) {
        guard sender === self.topViewController else {
            self.navigationBarAppearanceForController[sender.hashValue]?.backgroundColor = color
            return
        }
        return self.changeBackgroundColor(color)
    }

    /// Change alpha of shadow view
    func changeShadowViewAlpha(_ alpha: CGFloat, sender: UIViewController) {
        guard sender === self.topViewController else {
            self.navigationBarAppearanceForController[sender.hashValue]?.shadowViewAlpha = alpha
            return
        }
        return self.changeShadowViewAlpha(alpha)
    }

    /// Change navigation bar text color
    func changeTextColor(_ color: UIColor, sender: UIViewController) {
        guard sender === self.topViewController else {
            self.navigationBarAppearanceForController[sender.hashValue]?.textColor = color
            return
        }
        return self.changeTextColor(color)
    }

    /// Change navigation bar tint color
    func changeTintColor(_ color: UIColor, sender: UIViewController) {
        guard sender === self.topViewController else {
            self.navigationBarAppearanceForController[sender.hashValue]?.tintColor = color
            return
        }
        return self.changeTintColor(color)
    }

    /// Change status bar style
    func changeStatusBarStyle(_ style: UIStatusBarStyle, sender: UIViewController) {
        guard sender === self.topViewController else {
            return
        }
        return self.changeStatusBarStyle(style)
    }

    /// Adds an delegate to the delegates collection.
    func addDelegate(_ delegate: UINavigationControllerDelegate) {
        self.multicastDelegate.add(delegate)
    }

    /// Removes an delegate from the delegates collection.
    func removeDelegate(_ delegate: UINavigationControllerDelegate) {
        self.multicastDelegate.remove(delegate)
    }

    // MARK: Private API

    private func changeBackgroundColor(_ color: UIColor) {
        self.navigationBar.isTranslucent = true
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)

        self.navigationBar.backgroundColor = color
        self.statusBarView.backgroundColor = color

        if let topViewController = self.topViewController {
            self.navigationBarAppearanceForController[topViewController.hashValue]?.backgroundColor = color
        }
    }

    private func changeShadowViewAlpha(_ alpha: CGFloat) {
        let alpha = self.normalizeAlphaValue(alpha)
        self.navigationBar.shadowImage = UIImage()
        self.shadowView.backgroundColor = Appearance.shadowViewColor.withAlphaComponent(alpha)

        if let topViewController = self.topViewController {
            self.navigationBarAppearanceForController[topViewController.hashValue]?.shadowViewAlpha = alpha
        }
    }

    private func changeTextColor(_ color: UIColor) {
        self.navigationBar.titleTextAttributes = [
            .font: Appearance.titleFont,
            .foregroundColor: color
        ]

        if let topViewController = self.topViewController {
            self.navigationBarAppearanceForController[topViewController.hashValue]?.textColor = color
        }
    }

    private func changeTintColor(_ color: UIColor) {
        self.navigationBar.tintColor = color

        if let topViewController = self.topViewController {
            self.navigationBarAppearanceForController[topViewController.hashValue]?.tintColor = color
        }
    }

    private func changeStatusBarStyle(_ style: UIStatusBarStyle) {
        self.statusBarStyle = style

        if let topViewController = self.topViewController {
            self.navigationBarAppearanceForController[topViewController.hashValue]?.statusBarStyle = style
        }
    }

    private func setupAppearance() {
        self.view.addSubview(self.statusBarView)

        self.navigationBar.addSubview(self.shadowView)
        self.shadowView.translatesAutoresizingMaskIntoConstraints = false
        self.shadowView.snp.makeConstraints { make in
            make.bottom.equalTo(self.navigationBar.snp.bottom)
            make.height.equalTo(Appearance.shadowViewHeight)

            self.shadowViewLeadingConstraint = make.leading.equalToSuperview().constraint
            self.shadowViewTrailingConstraint = make.trailing.equalToSuperview().constraint
        }

        self.changeBackgroundColor(StyledNavigationController.Appearance.backgroundColor)
        self.changeTextColor(StyledNavigationController.Appearance.tintColor)
        self.changeTintColor(StyledNavigationController.Appearance.tintColor)
        self.changeShadowViewAlpha(1.0)
        self.changeStatusBarStyle(self.statusBarStyle)
    }

    private func normalizeAlphaValue(_ alpha: CGFloat) -> CGFloat {
        return max(0.0, min(1.0, alpha))
    }

    private func getNavigationBarAppearance(for viewController: UIViewController) -> NavigationBarAppearanceState {
        if let presentableViewController = viewController as? StyledNavigationControllerPresentable,
           !presentableViewController.shouldSaveAppearanceState {
            return NavigationBarAppearanceState()
        }

        let appearance: NavigationBarAppearanceState = {
            let defaultAppearance: NavigationBarAppearanceState
            if let presentableViewController = viewController as? StyledNavigationControllerPresentable {
                defaultAppearance = presentableViewController.navigationBarAppearanceOnFirstPresentation
            } else {
                defaultAppearance = NavigationBarAppearanceState()
            }
            return self.navigationBarAppearanceForController[viewController.hashValue] ?? defaultAppearance
        }()

        self.navigationBarAppearanceForController[viewController.hashValue] = appearance
        return appearance
    }

    private func removeNavigationBarAppearance(for viewController: UIViewController) {
        self.navigationBarAppearanceForController.removeValue(forKey: viewController.hashValue)
    }

    private func animateShadowView(transitionCoordinator: UIViewControllerTransitionCoordinator) {
        guard let fromViewController = self.transitionCoordinator?.viewController(forKey: .from),
              let toViewController = self.transitionCoordinator?.viewController(forKey: .to) else {
            return
        }

        let targetControllerAppearance = self.getNavigationBarAppearance(for: toViewController)
        let sourceControllerAppearance = self.getNavigationBarAppearance(for: fromViewController)

        let shouldShadowViewAppear = sourceControllerAppearance.shadowViewAlpha
            < targetControllerAppearance.shadowViewAlpha && sourceControllerAppearance.shadowViewAlpha.isEqual(to: 0.0)
        let shouldShadowViewDisappear = sourceControllerAppearance.shadowViewAlpha
            > targetControllerAppearance.shadowViewAlpha && targetControllerAppearance.shadowViewAlpha.isEqual(to: 0.0)

        let previousLeadingConstraintOffset = self.shadowViewLeadingConstraint?.layoutConstraints.first?.constant ?? 0
        let previousTrailingConstraintOffset = self.shadowViewTrailingConstraint?.layoutConstraints.first?.constant ?? 0

        if self.lastAction == .push {
            if shouldShadowViewAppear {
                self.shadowViewLeadingConstraint?.update(offset: self.navigationBar.frame.width)
                self.shadowViewTrailingConstraint?.update(offset: 0)
            } else if shouldShadowViewDisappear {
                self.shadowViewLeadingConstraint?.update(offset: 0)
                self.shadowViewTrailingConstraint?.update(offset: 0)
            }
        } else if self.lastAction == .pop {
            if shouldShadowViewAppear {
                self.shadowViewLeadingConstraint?.update(offset: 0)
                self.shadowViewTrailingConstraint?.update(offset: -self.navigationBar.frame.width)
            } else if shouldShadowViewDisappear {
                self.shadowViewLeadingConstraint?.update(offset: 0)
                self.shadowViewTrailingConstraint?.update(offset: 0)
            }
        }

        self.navigationBar.setNeedsLayout()
        self.navigationBar.layoutIfNeeded()

        transitionCoordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }

                if strongSelf.lastAction == .push {
                    if shouldShadowViewAppear {
                        strongSelf.shadowViewLeadingConstraint?.update(offset: 0)
                    } else if shouldShadowViewDisappear {
                        strongSelf.shadowViewTrailingConstraint?.update(offset: -strongSelf.navigationBar.frame.width)
                    }
                } else if strongSelf.lastAction == .pop {
                    if shouldShadowViewAppear {
                        strongSelf.shadowViewTrailingConstraint?.update(offset: 0)
                    } else if shouldShadowViewDisappear {
                        strongSelf.shadowViewLeadingConstraint?.update(offset: strongSelf.navigationBar.frame.width)
                    }
                }
            },
            completion: { [weak self] context in
                guard let strongSelf = self else {
                    return
                }

                if !context.isCancelled {
                    if shouldShadowViewDisappear {
                        // Restore hidden to make possible change alpha
                        strongSelf.shadowViewLeadingConstraint?.update(offset: 0)
                        strongSelf.shadowViewTrailingConstraint?.update(offset: 0)
                    }
                } else {
                    // Reset constraints if cancelled
                    strongSelf.shadowViewLeadingConstraint?.update(offset: previousLeadingConstraintOffset)
                    strongSelf.shadowViewTrailingConstraint?.update(offset: previousTrailingConstraintOffset)
                }
                strongSelf.navigationBar.layoutIfNeeded()
            }
        )
    }
}

// MARK: - StyledNavigationController: UINavigationControllerDelegate -

extension StyledNavigationController: UINavigationControllerDelegate {
    // MARK: Responding to a View Controller Being Shown

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        self.multicastDelegate.invoke { delegate in
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }

        let targetControllerAppearance = self.getNavigationBarAppearance(for: viewController)

        guard animated, let fromViewController = self.transitionCoordinator?.viewController(forKey: .from) else {
            self.changeBackgroundColor(targetControllerAppearance.backgroundColor)
            self.changeShadowViewAlpha(targetControllerAppearance.shadowViewAlpha)
            self.changeTextColor(targetControllerAppearance.textColor)
            self.changeTintColor(targetControllerAppearance.tintColor)
            self.changeStatusBarStyle(targetControllerAppearance.statusBarStyle)

            self.navigationBar.setNeedsLayout()
            self.navigationBar.layoutIfNeeded()

            if self.lastAction == .pop && !self.viewControllers.contains(viewController) {
                self.removeNavigationBarAppearance(for: viewController)
            }
            return
        }

        guard let coordinator = self.transitionCoordinator else {
            return
        }

        self.animateShadowView(transitionCoordinator: coordinator)
        self.changeStatusBarStyle(targetControllerAppearance.statusBarStyle)

        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }

                // change appearance w/o status bar style
                strongSelf.changeBackgroundColor(targetControllerAppearance.backgroundColor)
                strongSelf.changeShadowViewAlpha(targetControllerAppearance.shadowViewAlpha)
                strongSelf.changeTextColor(targetControllerAppearance.textColor)
                strongSelf.changeTintColor(targetControllerAppearance.tintColor)
            },
            completion: { [weak self] context in
                guard let strongSelf = self else {
                    return
                }

                if !context.isCancelled {
                    // Workaround for strange bug with titleTextAttributes & non-interactive pop
                    // rdar://37567828
                    strongSelf.changeTextColor(targetControllerAppearance.textColor)
                    strongSelf.navigationBar.setNeedsLayout()
                    strongSelf.navigationBar.layoutIfNeeded()

                    if strongSelf.lastAction == .pop && !strongSelf.viewControllers.contains(viewController) {
                        strongSelf.removeNavigationBarAppearance(for: viewController)
                    }
                } else {
                    // Rollback appearance
                    let sourceControllerAppearance = strongSelf.getNavigationBarAppearance(for: fromViewController)

                    strongSelf.changeBackgroundColor(sourceControllerAppearance.backgroundColor)
                    strongSelf.changeShadowViewAlpha(sourceControllerAppearance.shadowViewAlpha)
                    strongSelf.changeTextColor(sourceControllerAppearance.textColor)
                    strongSelf.changeTintColor(sourceControllerAppearance.tintColor)
                    strongSelf.changeStatusBarStyle(sourceControllerAppearance.statusBarStyle)
                }
            }
        )
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        self.multicastDelegate.invoke { delegate in
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    // MARK: Supporting Custom Transition Animations

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        var animatedTransitioning: UIViewControllerAnimatedTransitioning?

        self.multicastDelegate.invoke { delegate in
            if animatedTransitioning != nil {
                return
            }

            if let transitioning = delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            ) {
                animatedTransitioning = transitioning
            }
        }

        return animatedTransitioning
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        var interactiveTransitioning: UIViewControllerInteractiveTransitioning?

        self.multicastDelegate.invoke { delegate in
            if interactiveTransitioning != nil {
                return
            }

            if let transitioning = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            ) {
                interactiveTransitioning = transitioning
            }
        }

        return interactiveTransitioning
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        var interfaceOrientation: UIInterfaceOrientation?

        self.multicastDelegate.invoke { delegate in
            if interfaceOrientation != nil {
                return
            }

            if let orientation = delegate.navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) {
                interfaceOrientation = orientation
            }
        }

        if let interfaceOrientation = interfaceOrientation {
            return interfaceOrientation
        }

        return DeviceInfo.current.orientation.interface
    }

    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        var interfaceOrientationMask: UIInterfaceOrientationMask?

        self.multicastDelegate.invoke { delegate in
            if interfaceOrientationMask != nil {
                return
            }

            if let mask = delegate.navigationControllerSupportedInterfaceOrientations?(navigationController) {
                interfaceOrientationMask = mask
            }
        }

        if let interfaceOrientationMask = interfaceOrientationMask {
            return interfaceOrientationMask
        }

        return .all
    }
}

// MARK: - Default appearance protocol

protocol StyledNavigationControllerPresentable: class {
    /// Appearance for navigation bar, status bar, etc when controller first time presented
    var navigationBarAppearanceOnFirstPresentation: StyledNavigationController.NavigationBarAppearanceState { get }
    /// Determine whether controller should store appearance state and restore it when return back
    var shouldSaveAppearanceState: Bool { get }
}

extension StyledNavigationControllerPresentable {
    var navigationBarAppearanceOnFirstPresentation: StyledNavigationController.NavigationBarAppearanceState {
        return StyledNavigationController.NavigationBarAppearanceState()
    }

    var shouldSaveAppearanceState: Bool {
        return true
    }
}

// MARK: - Color transition helper

final class ColorTransitionHelper {
    static func makeTransitionColor(
        from sourceColor: UIColor,
        to targetColor: UIColor,
        transitionProgress: CGFloat
    ) -> UIColor {
        let progress = max(0, min(1, transitionProgress))

        var fRed: CGFloat = 0
        var fBlue: CGFloat = 0
        var fGreen: CGFloat = 0
        var fAlpha: CGFloat = 0

        var tRed: CGFloat = 0
        var tBlue: CGFloat = 0
        var tGreen: CGFloat = 0
        var tAlpha: CGFloat = 0

        sourceColor.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        targetColor.getRed(&tRed, green: &tGreen, blue: &tBlue, alpha: &tAlpha)

        let red: CGFloat = (progress * (tRed - fRed)) + fRed
        let green: CGFloat = (progress * (tGreen - fGreen)) + fGreen
        let blue: CGFloat = (progress * (tBlue - fBlue)) + fBlue
        let alpha: CGFloat = (progress * (tAlpha - fAlpha)) + fAlpha

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
