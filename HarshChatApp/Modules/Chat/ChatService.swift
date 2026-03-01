//
//  ChatService.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

final class ChatService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    func sendMessage(chatId: String, messageData: [String: Any]) async throws {
        try await db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)
    }
    
    func uploadChatImage(data: Data, chatId: String) async throws -> String {
        let fileName = Int(Date().timeIntervalSince1970)
        let ref = storage.child("chat_images/\(chatId)/\(fileName).jpg")
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
