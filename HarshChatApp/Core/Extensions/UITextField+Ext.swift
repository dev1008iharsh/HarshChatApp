//
//  UITextField+Ext.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import UIKit

// MARK: - UITextField Extension

/// A collection of helper methods and factory functions to simplify UITextField setup.
extension UITextField {
    // MARK: - Factory Methods

    /// Creates a pre-configured profile text field with consistent styling.
    /// - Parameters:
    ///   - placeholder: The placeholder text for the field.
    ///   - text: The initial text value.
    ///   - isEnabled: Boolean to toggle the field's interaction and styling.
    /// - Returns: A styled UITextField instance ready for use.
    static func createProfileField(placeholder: String, text: String, isEnabled: Bool = true) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.text = text
        tf.isEnabled = isEnabled
        tf.backgroundColor = .secondarySystemGroupedBackground
        tf.layer.cornerRadius = 10
        tf.font = AppFont.light.set(size: 16)

        // MARK: Dynamic Styling

        // Changing text color based on the state for better UX visibility.
        tf.textColor = isEnabled ? AppColor.primaryText : AppColor.secondaryText
        tf.setLeftPaddingPoints(15)

        // Setting fixed height for standard UI appearance across the app.
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true

        print("🛠️ [Debug] UI: Created ProfileField with placeholder: '\(placeholder)'")
        return tf
    }

    // MARK: - Helper Methods

    /// Adds a horizontal padding to the left side of the UITextField.
    /// - Parameter amount: The width of the padding view.
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        leftView = paddingView
        leftViewMode = .always
    }
}
