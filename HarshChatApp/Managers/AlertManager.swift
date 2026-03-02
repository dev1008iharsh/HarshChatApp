//
//  AlertManager.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import UIKit

// MARK: - SheetAction Model

/// Custom model to define actions for Action Sheets.
struct SheetAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: () -> Void
}

// MARK: - AlertManager

/// A centralized manager to handle all types of UI Alerts and Action Sheets.
final class AlertManager {
    // MARK: - Standard Alerts

    @MainActor
    /// Shows a simple alert with an "OK" button.
    static func showAlert(title: String, message: String, vc: UIViewController?) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        targetVC.present(alert, animated: true)
    }

    @MainActor
    /// Shows an alert with a custom callback for the "OK" action.
    static func showAlertWithHandler(title: String, message: String, vc: UIViewController?, okAction: ((UIAlertAction) -> Void)? = nil) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))
        targetVC.present(alert, animated: true)
    }

    // MARK: - Confirmation Alerts

    @discardableResult
    @MainActor
    /// Shows a two-button confirmation alert.
    static func showConfirmationAlert(
        title: String,
        message: String,
        vc: UIViewController?,
        rightBtnTitle: String = "Confirm",
        rightBtnStyle: UIAlertAction.Style = .destructive,
        leftBtnTitle: String = "Cancel",
        leftBtnStyle: UIAlertAction.Style = .cancel,
        rightAction: @escaping (UIAlertAction) -> Void,
        leftAction: ((UIAlertAction) -> Void)? = nil
    ) -> UIAlertController? {
        guard let targetVC = vc else { return nil }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let left = UIAlertAction(title: leftBtnTitle, style: leftBtnStyle, handler: leftAction)
        alert.addAction(left)

        let right = UIAlertAction(title: rightBtnTitle, style: rightBtnStyle, handler: rightAction)
        alert.addAction(right)

        targetVC.present(alert, animated: true)
        return alert
    }

    // MARK: - Action Sheets

    @MainActor
    /// Shows a bottom action sheet with multiple custom actions.
    static func showActionSheet(on vc: UIViewController?, title: String?, message: String?, actions: [SheetAction]) {
        guard let targetVC = vc else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler()
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // iPad Support: Popover configuration to prevent crash on iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = targetVC.view
            popoverController.sourceRect = CGRect(x: targetVC.view.bounds.midX, y: targetVC.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        print("📢 [Debug] UI: Presenting Action Sheet: \(title ?? "No Title")")
        targetVC.present(alert, animated: true)
    }
}
