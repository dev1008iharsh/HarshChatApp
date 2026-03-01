import UIKit

struct AppColor {
    static let primaryTeal = UIColor(red: 0.05, green: 0.65, blue: 0.35, alpha: 1.0)
    static let darkHeader = UIColor(red: 0.12, green: 0.17, blue: 0.20, alpha: 1.0)

    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.07, green: 0.11, blue: 0.13, alpha: 1.0) : .white
    }

    static let outgoingBubble = UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.02, green: 0.28, blue: 0.24, alpha: 1.0) :
            UIColor(red: 0.89, green: 0.99, blue: 0.82, alpha: 1.0)
    }

    static let incomingBubble = UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.13, green: 0.18, blue: 0.21, alpha: 1.0) : .white
    }

    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    static let systemRed = UIColor.systemRed
}
