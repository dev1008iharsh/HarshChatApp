//
//  AppFont.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import UIKit

// MARK: - AppFont

/// Defines custom font styles for the application.
enum AppFont: String {
    case bold = "GoogleSansCode-Bold"
    case semiBold = "GoogleSansCode-SemiBold"
    case medium = "GoogleSansCode-Medium"
    case regular = "GoogleSansCode-Regular"
    case light = "GoogleSansCode-Light"

    // MARK: - Font Factory

    /// Returns a UIFont instance for the specified size.
    func set(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: rawValue, size: size) else {
            print("⚠️ [Debug] Font: '\(rawValue)' not found, using system font.")
            return .systemFont(ofSize: size)
        }
        return font
    }
}
