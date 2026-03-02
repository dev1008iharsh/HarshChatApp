//
//  ChatService.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

// MARK: - ChatService

final class ChatService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    // MARK: - Message Operations

    /// Sends a message and updates conversation summaries for both users using Async/Await.
    func sendMessage(chatId: String, otherUser: ChatUser, messageData: [String: Any], lastMessageText: String) async throws {
        // MAJOR EVENT: Validating current authentication session
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentPhone = Auth.auth().currentUser?.phoneNumber else {
            print("DEBUG: ChatService - Authentication failed or session expired.")
            return
        }

        // Attempt to get the current user's display name for the receiver's list
        let myName = Auth.auth().currentUser?.displayName ?? "User"

        // 1. MAJOR EVENT: Adding the actual message to the sub-collection
        try await db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)

        // 2. MAJOR EVENT: Updating My (Sender) Conversation List
        let myConversationData: [String: Any] = [
            "otherUserName": otherUser.displayName,
            "otherUserId": otherUser.senderId,
            "otherUserPhone": otherUser.phoneNumber,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": otherUser.profileImageUrl ?? "",
        ]

        try await db.collection("users").document(currentUid).collection("conversations").document(chatId).setData(myConversationData, merge: true)

        // 3. MAJOR EVENT: Updating Their (Receiver) Conversation List
        let otherConversationData: [String: Any] = [
            "otherUserName": myName,
            "otherUserId": currentUid,
            "otherUserPhone": currentPhone,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": "", // Future: Pass current user's profile image
        ]

        try await db.collection("users").document(otherUser.senderId).collection("conversations").document(chatId).setData(otherConversationData, merge: true)

        print("DEBUG: ChatService - Message and conversations synced successfully.")
    }

    // MARK: - Media Operations

    /// Uploads an image to Google Firebase Storage and returns the downloadable URL.
    func uploadChatImage(data: Data, chatId: String) async throws -> String {
        // MAJOR EVENT: Creating unique filename and path
        let fileName = UUID().uuidString
        let imageRef = storage.child("chat_images/\(chatId)/\(fileName).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("DEBUG: ChatService - Starting image upload for Chat: \(chatId)")

        // Put data into storage using async method
        _ = try await imageRef.putDataAsync(data, metadata: metadata)

        // Retrieve the public URL
        let downloadURL = try await imageRef.downloadURL()

        print("DEBUG: ChatService - Image upload success. URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }
}
