//
//  ChatListModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import FirebaseFirestore
import Foundation

// MARK: - Conversation Model

/// Represents a single chat preview in the main chat list (Home Screen).
/// This model maps the data stored in the 'conversations' sub-collection of a user.
struct Conversation {
    // Unique ID for the conversation (usually the same as ChatID).
    let id: String

    // Details of the person we are chatting with.
    let otherUserName: String
    let otherUserId: String
    let otherUserPhone: String

    // Preview of the most recent message sent or received.
    let lastMessage: String

    // The exact time the last message was recorded.
    let timestamp: Date

    // URL for the other user's profile picture.
    let profileImageUrl: String?

    // MARK: - Computed Properties

    /// Converts the timestamp into a human-readable string (e.g., "10:30 AM" or "Yesterday").
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Firestore Extension

extension Conversation {
    /// A custom initializer to easily convert a Firestore Document into a Conversation object.
    /// - Parameters:
    ///   - id: The document ID from Firestore.
    ///   - data: The dictionary containing fields like 'otherUserName', 'lastMessage', etc.
    init?(id: String, data: [String: Any]) {
        // Ensure all required fields exist, otherwise return nil (Failable Initializer).
        guard let name = data["otherUserName"] as? String,
              let userId = data["otherUserId"] as? String,
              let phone = data["otherUserPhone"] as? String,
              let message = data["lastMessage"] as? String,
              let fbTimestamp = data["timestamp"] as? Timestamp else {
            return nil
        }

        self.id = id
        otherUserName = name
        otherUserId = userId
        otherUserPhone = phone
        lastMessage = message
        timestamp = fbTimestamp.dateValue() // Convert Firestore Timestamp to Swift Date.
        profileImageUrl = data["profileImageUrl"] as? String
    }
}
