import UIKit

struct SheetAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: () -> Void
}

final class AlertManager {
    @MainActor
    static func showAlert(title: String, message: String, vc: UIViewController?) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        targetVC.present(alert, animated: true)
    }

    @MainActor
    static func showAlertHandler(title: String, message: String, vc: UIViewController?, okAction: @escaping (UIAlertAction) -> Void) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))
        targetVC.present(alert, animated: true)
    }

    @discardableResult
    @MainActor
    static func showConfirmationAlert(
        title: String,
        message: String,
        vc: UIViewController?,
        rightBtnTitle: String,
        rightBtnStyle: UIAlertAction.Style = .destructive,
        leftBtnTitle: String,
        leftBtnStyle: UIAlertAction.Style = .cancel,
        rightAction: @escaping (UIAlertAction) -> Void,
        leftAction: @escaping (UIAlertAction) -> Void
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

    @MainActor
    static func showActionSheet(on vc: UIViewController?, title: String?, message: String?, actions: [SheetAction]) {
        guard let targetVC = vc else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        targetVC.present(alert, animated: true)
    }
}
