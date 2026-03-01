//
//  AppFont.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

/// AppFont manages all typography for HarshChatApp
/// Consistent with 2026 Swift standards
enum AppFont: String {
    case bold = "GoogleSansCode-Bold"
    case semiBold = "GoogleSansCode-SemiBold"
    case medium = "GoogleSansCode-Medium"
    case regular = "GoogleSansCode-Regular"
    case light = "GoogleSansCode-Light"
    
    /// Returns the custom font with a specific size
    /// - Parameter size: The desired font size
    /// - Returns: A UIFont instance
    func set(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: self.rawValue, size: size) else {
            // Log error for developers to debug Info.plist or Target Membership
            print("❌ Error: Font \(self.rawValue) not found. Falling back to system font.")
            return UIFont.systemFont(ofSize: size)
        }
        return font
    }
}
