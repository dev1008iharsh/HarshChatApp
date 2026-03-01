import UIKit

enum AppFont: String {
    case bold = "GoogleSansCode-Bold"
    case semiBold = "GoogleSansCode-SemiBold"
    case medium = "GoogleSansCode-Medium"
    case regular = "GoogleSansCode-Regular"
    case light = "GoogleSansCode-Light"

    func set(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: rawValue, size: size) else {
            return .systemFont(ofSize: size)
        }
        return font
    }
}
