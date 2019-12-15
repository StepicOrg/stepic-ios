//
//  ControllerWithStepikPlaceholder.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 20.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import SnapKit
import UIKit

typealias StepikPlaceholderControllerState = StepikPlaceholderControllerContainer.PlaceholderState

class StepikPlaceholderControllerContainer: StepikPlaceholderViewDelegate {
    static let shared = StepikPlaceholderControllerContainer()

    open class PlaceholderState: Equatable, Hashable {
        var id: String

        init(id: String) {
            self.id = id
        }

        static let anonymous = PlaceholderState(id: "anonymous")
        static let connectionError = PlaceholderState(id: "connectionError")
        static let refreshing = PlaceholderState(id: "refreshing")
        static let empty = PlaceholderState(id: "empty")
        static let adaptiveCoursePassed = PlaceholderState(id: "adaptiveCoursePassed")

        var hashValue: Int {
            get {
                return id.hashValue
            }
        }

        public static func == (lhs: PlaceholderState, rhs: PlaceholderState) -> Bool {
            return lhs.id == rhs.id
        }
    }

    var registeredPlaceholders: [PlaceholderState: StepikPlaceholder] = [:]
    var currentPlaceholderButtonAction: (() -> Void)?
    var isPlaceholderShown: Bool = false

    lazy var placeholderView: StepikPlaceholderView = {
        let view = StepikPlaceholderView()
        return view
    }()

    func buttonDidClick(_ button: UIButton) {
        currentPlaceholderButtonAction?()
    }
}

protocol ControllerWithStepikPlaceholder: AnyObject {
    var isPlaceholderShown: Bool { get set }
    var placeholderContainer: StepikPlaceholderControllerContainer { get set }

    func registerPlaceholder(placeholder: StepikPlaceholder, for state: StepikPlaceholderControllerState)
    func showPlaceholder(for state: StepikPlaceholderControllerState)
}

extension ControllerWithStepikPlaceholder where Self: UIViewController {
    var isPlaceholderShown: Bool {
        set {
            placeholderContainer.placeholderView.isHidden = !newValue
            placeholderContainer.isPlaceholderShown = newValue
        }
        get {
            return placeholderContainer.isPlaceholderShown
        }
    }

    func registerPlaceholder(placeholder: StepikPlaceholder, for state: StepikPlaceholderControllerState) {
        placeholderContainer.registeredPlaceholders[state] = placeholder
    }

    func showPlaceholder(for state: StepikPlaceholderControllerState) {
        guard let placeholder = placeholderContainer.registeredPlaceholders[state] else {
            return
        }

        updatePlaceholderLayout()
        placeholderContainer.placeholderView.set(placeholder: placeholder.style)
        placeholderContainer.placeholderView.delegate = placeholderContainer
        placeholderContainer.currentPlaceholderButtonAction = placeholder.buttonAction

        isPlaceholderShown = true
    }

    private func updatePlaceholderLayout() {
        guard let view = self.view else {
            return
        }

        if placeholderContainer.placeholderView.superview == nil {
            placeholderContainer.placeholderView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(placeholderContainer.placeholderView)

            placeholderContainer.placeholderView.snp.makeConstraints { $0.center.edges.equalTo(view) }

            placeholderContainer.placeholderView.setNeedsLayout()
            placeholderContainer.placeholderView.layoutIfNeeded()
        }
        view.bringSubviewToFront(placeholderContainer.placeholderView)
    }
}
