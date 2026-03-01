//
//  ChatViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import Foundation
import MessageKit
import FirebaseFirestore
import FirebaseAuth

final class ChatViewModel {
    private let service = ChatService()
    private let db = Firestore.firestore()
    private let chatId: String
    private var listener: ListenerRegistration?
    
    let currentUser = Sender(senderId: Auth.auth().currentUser?.uid ?? "", displayName: "Me")
    var messages = [Message]()
    
    var onMessagesUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    init(chatId: String) {
        self.chatId = chatId
    }

    func listenForMessages() {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String ?? ""
                    let displayName = data["senderName"] as? String ?? ""
                    let sentDate = (data["sentDate"] as? Timestamp)?.dateValue() ?? Date()
                    let sender = Sender(senderId: senderId, displayName: displayName)
                    
                    if let text = data["text"] as? String {
                        return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .text(text))
                    } else if let imageUrl = data["imageUrl"] as? String, let url = URL(string: imageUrl) {
                        let media = ImageMediaItem(url: url, image: nil, placeholderImage: UIImage(systemName: "photo")!, size: CGSize(width: 200, height: 200))
                        return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .photo(media))
                    }
                    return nil
                }
                self.onMessagesUpdated?()
            }
    }

    func sendText(_ text: String) {
        let data: [String: Any] = [
            "senderId": currentUser.senderId,
            "senderName": currentUser.displayName,
            "sentDate": FieldValue.serverTimestamp(),
            "text": text
        ]
        Task {
            do { try await service.sendMessage(chatId: chatId, messageData: data) }
            catch { onError?(error.localizedDescription) }
        }
    }

    func sendImage(_ data: Data) {
        Task {
            do {
                let url = try await service.uploadChatImage(data: data, chatId: chatId)
                let messageData: [String: Any] = [
                    "senderId": currentUser.senderId,
                    "senderName": currentUser.displayName,
                    "sentDate": FieldValue.serverTimestamp(),
                    "imageUrl": url
                ]
                try await service.sendMessage(chatId: chatId, messageData: messageData)
            } catch {
                onError?(error.localizedDescription)
            }
        }
    }

    deinit { listener?.remove() }
}
