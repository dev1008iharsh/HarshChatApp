//
//  SettingsModels.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import UIKit

/// Represents a group of settings (e.g., "Account", "Help", "Actions")
struct SettingsSection {
    let title: String? // Section header title (optional)
    var options: [SettingsOption] // Array of rows within this section
}

/// Represents a single row/item in the Settings table
struct SettingsOption {
    let title: String
    let subtitle: String?
    let iconName: String // SF Symbol name
    let iconBackgroundColor: UIColor
    let iconTintColor: UIColor
    let titleColor: UIColor
    let isLogout: Bool // Flag to identify critical actions (red text/logic)

    // MAJOR EVENT: Closure to handle tap actions without hardcoding in VC
    let handler: () -> Void
}
