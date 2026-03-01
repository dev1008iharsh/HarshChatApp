//
//  UITextField+Ext.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

/// Extensions for UITextField to add custom UI enhancements
extension UITextField {
    
    /// Adds a horizontal padding to the left of the text field
    /// - Parameter amount: The amount of space in points
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
