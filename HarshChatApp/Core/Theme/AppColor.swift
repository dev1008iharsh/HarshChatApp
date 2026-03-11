//
//  AppColor.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import UIKit

// MARK: - AppColor

/// Centralized color palette for the application
struct AppColor {
    // MARK: - Brand Colors

    // Primary green brand color
    static let primaryColor = UIColor(
        red: 0.145,
        green: 0.827,
        blue: 0.400,
        alpha: 1.0
    )

    // Darker shade for header backgrounds
    static let darkHeader = UIColor(red: 0.12, green: 0.17, blue: 0.20, alpha: 1.0)

    // MARK: - Dynamic Backgrounds

    // Adapts background color based on Light/Dark mode

    static let background = UIColor { _ in
        .systemGroupedBackground
    }

    static let secondaryBackground = UIColor { _ in
        .tertiarySystemBackground
    }

    /*
     static let background = UIColor { trait in
         trait.userInterfaceStyle == .dark ?
         UIColor(
             red: 0.07,
             green: 0.11,
             blue: 0.13,
             alpha: 1.0
         ) : .systemBackground
     }*/

    // MARK: - Chat Bubbles

    // Dynamic color for sent message bubbles
    static let outgoingBubble = UIColor { trait in

        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.02, green: 0.35, blue: 0.30, alpha: 1.0) :
            UIColor(red: 0.7, green: 0.97, blue: 0.85, alpha: 1.0)
    }

    // Dynamic color for received message bubbles
    static let incomingBubble = UIColor { trait in

        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.15, green: 0.20, blue: 0.23, alpha: 1.0) :
            UIColor(red: 0.8, green: 0.94, blue: 0.96, alpha: 1.0)
    }

    // MARK: - Text & System Colors

    // Standard label and system colors
    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    static let systemRed = UIColor.systemRed
}
