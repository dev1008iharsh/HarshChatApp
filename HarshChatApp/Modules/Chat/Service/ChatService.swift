import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Foundation

final class ChatService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    func sendMessage(chatId: String, otherUser: ChatUser, messageData: [String: Any], lastMessageText: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentPhone = Auth.auth().currentUser?.phoneNumber else { return }
        
        try await db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)
        
        let myConversationData: [String: Any] = [
            "otherUserName": otherUser.displayName,
            "otherUserId": otherUser.senderId,
            "otherUserPhone": otherUser.phoneNumber,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": otherUser.profileImageUrl ?? ""
        ]
        try await db.collection("users").document(currentUid).collection("conversations").document(chatId).setData(myConversationData)
        
        let otherConversationData: [String: Any] = [
            "otherUserName": "User",
            "otherUserId": currentUid,
            "otherUserPhone": currentPhone,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": ""
        ]
        try await db.collection("users").document(otherUser.senderId).collection("conversations").document(chatId).setData(otherConversationData)
    }
    
    func uploadChatImage(data: Data, chatId: String) async throws -> String {
        let fileName = Int(Date().timeIntervalSince1970)
        let ref = storage.child("chat_images/\(chatId)/\(fileName).jpg")
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
