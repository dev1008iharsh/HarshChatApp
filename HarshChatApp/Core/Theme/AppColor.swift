//
//  AppColor.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

/// AppColor provides a centralized palette for HarshChatApp
struct AppColor {
    
    // MARK: - Brand Colors
    static let primaryTeal = UIColor(red: 0.05, green: 0.65, blue: 0.35, alpha: 1.0)
    static let darkHeader = UIColor(red: 0.12, green: 0.17, blue: 0.20, alpha: 1.0)
    
    // MARK: - Dynamic Backgrounds
    static let background = UIColor { trait in
        return trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.07, green: 0.11, blue: 0.13, alpha: 1.0) : .white
    }
    
    // MARK: - Chat Bubbles
    static let outgoingBubble = UIColor(red: 0.89, green: 0.99, blue: 0.82, alpha: 1.0)
    
    static let incomingBubble = UIColor { trait in
        return trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.13, green: 0.18, blue: 0.21, alpha: 1.0) : .white
    }
    
    // MARK: - Text Colors
    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
}
