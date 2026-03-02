//
//  MessageModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import Foundation
import MessageKit
import UIKit

// MARK: - Message Model

/// A model representing a single message in the chat conversation.
/// It conforms to MessageKit's 'MessageType' protocol.
struct Message: MessageType {
    // MARK: - MessageType Requirements

    /// The user who sent the message (conforming to SenderType).
    var sender: SenderType

    /// A unique identifier for the message (usually Firebase Document ID).
    /// Used by MessageKit to manage cell reuse and data consistency.
    var messageId: String

    /// The exact date and time when the message was sent.
    var sentDate: Date

    /// Defines what type of message this is (e.g., text, photo, video, location).
    /// 'MessageKind' is an enum provided by MessageKit.
    var kind: MessageKind
}

// MARK: - ImageMediaItem Model

/// A helper model to handle image/media content within a message.
/// It conforms to MessageKit's 'MediaItem' protocol.
struct ImageMediaItem: MediaItem {
    // MARK: - MediaItem Requirements

    /// The remote URL of the image stored in Firebase Storage.
    var url: URL?

    /// The actual image object (if already downloaded or picked from library).
    var image: UIImage?

    /// A default image to show while the actual photo is being downloaded.
    var placeholderImage: UIImage

    /// The dimensions of the image bubble in the chat UI.
    var size: CGSize
}

// MARK: - Message Extension (Helper)

extension Message {
    /// A helper computed property to determine if the message is from the current user.
    /// This helps in setting different bubble colors or alignments in the UI.
    func isFromCurrentUser(currentUserId: String) -> Bool {
        return sender.senderId == currentUserId
    }
}
