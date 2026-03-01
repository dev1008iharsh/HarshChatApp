import Foundation
import MessageKit

struct ChatUser: SenderType {
    var senderId: String
    var displayName: String
    var phoneNumber: String
    var profileImageUrl: String?
}
