//
//  Conversation.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import Foundation
import FirebaseFirestore

struct Conversation {
    let id: String
    let otherUserName: String
    let otherUserId: String
    let lastMessage: String
    let timestamp: Date
    let profileImageUrl: String?
}
