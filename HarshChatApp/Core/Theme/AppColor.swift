import UIKit

struct AppColor {
    static let primaryColor = UIColor(
        red: 0.145,
        green: 0.827,
        blue: 0.400,
        alpha: 1.0
    )
    static let darkHeader = UIColor(red: 0.12, green: 0.17, blue: 0.20, alpha: 1.0)

    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 0.07, green: 0.11, blue: 0.13, alpha: 1.0) : .white
    }

    static let outgoingBubble = UIColor { trait in
            trait.userInterfaceStyle == .dark ?
                UIColor(red: 0.02, green: 0.35, blue: 0.30, alpha: 1.0) :
                UIColor(red: 0.88, green: 0.97, blue: 0.85, alpha: 1.0)
        }

        static let incomingBubble = UIColor { trait in
            trait.userInterfaceStyle == .dark ?
                UIColor(red: 0.15, green: 0.20, blue: 0.23, alpha: 1.0) :
                UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
        }

    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    static let systemRed = UIColor.systemRed
}
