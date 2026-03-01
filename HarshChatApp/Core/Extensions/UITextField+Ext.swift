//
//  UITextField+Ext.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

extension UITextField {
    static func createProfileField(placeholder: String, text: String, isEnabled: Bool = true) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.text = text
        tf.isEnabled = isEnabled
        tf.backgroundColor = .secondarySystemGroupedBackground
        tf.layer.cornerRadius = 10
        tf.font = AppFont.light.set(size: 16)
        tf.textColor = isEnabled ? .label : .secondaryLabel
        tf.setLeftPaddingPoints(15)
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
    }

    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        leftView = paddingView
        leftViewMode = .always
    }
}
