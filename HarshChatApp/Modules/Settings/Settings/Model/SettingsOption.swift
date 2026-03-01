import UIKit

struct SettingsSection {
    let title: String?
    var options: [SettingsOption]
}

struct SettingsOption {
    let title: String
    let subtitle: String?
    let iconName: String
    let iconBackgroundColor: UIColor
    let iconTintColor: UIColor
    let titleColor: UIColor
    let isLogout: Bool
    let handler: () -> Void
}
