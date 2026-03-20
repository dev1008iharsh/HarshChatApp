//
//  ChatUser.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import Foundation
import MessageKit
import FirebaseAuth

// MARK: - ChatUser Model

/// A model representing a user in the chat system.
/// It conforms to MessageKit's 'SenderType' protocol to identify who sent a message.
struct ChatUser: SenderType {
    // MARK: - SenderType Requirements

    /// A unique identifier for the sender (usually Firebase UID).
    /// MessageKit uses this to group messages from the same person.
    var senderId: String

    /// The name displayed above the message bubble or in the chat list.
    var displayName: String

    // MARK: - Custom App Properties

    /// The mobile number associated with the user account.
    /// Useful for identifying contacts within the app.
    var phoneNumber: String

    /// Optional URL for the user's profile picture.
    /// Can be used to show an avatar next to the message bubble.
    var profileImageUrl: String?
}

// MARK: - Model Extension

extension ChatUser {
    /// A helper computed property to check if this user is the currently logged-in user.
    /// Helpful for UI logic like showing bubbles on the right vs left side.
    var isCurrentUser: Bool {
        // You would typically compare this with Auth.auth().currentUser?.uid
        return senderId == Auth.auth().currentUser?.uid
        //return false // Placeholder logic
    }
}
