//
//  ChatListModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//
import Foundation
import FirebaseFirestore

struct Conversation {
    let id: String
    let otherUserName: String
    let otherUserId: String
    let otherUserPhone: String
    let lastMessage: String
    let timestamp: Date
    let profileImageUrl: String?
}
