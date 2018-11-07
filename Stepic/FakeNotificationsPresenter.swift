//
//  FakeNotificationsPresenter.swift
//  Stepic
//
//  Created by Alexander Karpov on 02.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import UIKit
import CRToast

final class FakeNotificationsPresenter {
    static func present(
        text: String,
        subtitle: String,
        success: @escaping (() -> Void)
    ) {
        let responder = CRToastInteractionResponder(
            interactionType: .tap,
            automaticallyDismiss: true,
            block: { _ in
                success()
            }
        )

        var toastOptions = self.getBaseToastOptions()
        toastOptions[kCRToastTextKey] = text
        toastOptions[kCRToastTextAlignmentKey] = NSTextAlignment.left
        toastOptions[kCRToastTextMaxNumberOfLinesKey] = 3
        toastOptions[kCRToastSubtitleTextKey] = subtitle
        toastOptions[kCRToastSubtitleTextAlignmentKey] = NSTextAlignment.left
        toastOptions[kCRToastSubtitleTextColorKey] = UIColor.lightGray
        toastOptions[kCRToastSubtitleTextMaxNumberOfLinesKey] = 3
        toastOptions[kCRToastTimeIntervalKey] = NSNumber(value: 10.0)
        toastOptions[kCRToastInteractionRespondersKey] = [responder]

        CRToastManager.showNotification(options: toastOptions) {
            print("show notification completed!")
        }
    }

    static func present(text: String, success: @escaping (() -> Void)) {
        let responder = CRToastInteractionResponder(
            interactionType: .tap,
            automaticallyDismiss: true,
            block: { _ in
                success()
            }
        )

        var toastOptions = self.getBaseToastOptions()
        toastOptions[kCRToastTextKey] = text
        toastOptions[kCRToastInteractionRespondersKey] = [responder]

        CRToastManager.showNotification(options: toastOptions) {
            print("show notification completed!")
        }
    }

    private static func getBaseToastOptions() -> [AnyHashable: Any] {
        return [
            kCRToastImageKey: Images.boundedStepicIcon,
            kCRToastNotificationTypeKey: NSNumber(value: CRToastType.navigationBar.rawValue),
            kCRToastNotificationPresentationTypeKey: NSNumber(value: CRToastPresentationType.cover.rawValue),
            kCRToastUnderStatusBarKey: true,
            kCRToastAnimationInTypeKey: NSNumber(value: CRToastAnimationType.gravity.rawValue),
            kCRToastAnimationOutTypeKey: NSNumber(value: CRToastAnimationType.gravity.rawValue),
            kCRToastAnimationInDirectionKey: NSNumber(value: CRToastAnimationDirection.top.rawValue),
            kCRToastAnimationOutDirectionKey: NSNumber(value: CRToastAnimationDirection.top.rawValue),
            kCRToastAnimationInTimeIntervalKey: 0.3,
            kCRToastTimeIntervalKey: 5.0,
            kCRToastAnimationOutTimeIntervalKey: 0.3,
            kCRToastTextMaxNumberOfLinesKey: 2,
            kCRToastImageContentModeKey: NSNumber(value: UIViewContentMode.scaleAspectFit.rawValue),
            kCRToastBackgroundColorKey: UIColor.black
        ]
    }
}
