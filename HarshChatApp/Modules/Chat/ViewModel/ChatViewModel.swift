import Foundation
import MessageKit
import FirebaseFirestore
import FirebaseAuth

final class ChatViewModel {
    private let service = ChatService()
    private let db = Firestore.firestore()
    let chatId: String
    let otherUser: ChatUser
    private var listener: ListenerRegistration?
    
    let currentUser = ChatUser(senderId: Auth.auth().currentUser?.uid ?? "",
                              displayName: "Me",
                              phoneNumber: Auth.auth().currentUser?.phoneNumber ?? "")
    
    var messages = [Message]()
    var onMessagesUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    init(chatId: String, otherUser: ChatUser) {
        self.chatId = chatId
        self.otherUser = otherUser
    }

    func listenForMessages() {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String ?? ""
                    let senderName = data["senderName"] as? String ?? ""
                    let sentDate = (data["sentDate"] as? Timestamp)?.dateValue() ?? Date()
                    let sender = ChatUser(senderId: senderId, displayName: senderName, phoneNumber: "")
                    
                    if let text = data["text"] as? String {
                        return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .text(text))
                    } else if let imageUrl = data["imageUrl"] as? String, let url = URL(string: imageUrl) {
                        let media = ImageMediaItem(url: url, image: nil, placeholderImage: UIImage(systemName: "photo")!, size: CGSize(width: 240, height: 240))
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
            do { try await service.sendMessage(chatId: chatId, otherUser: otherUser, messageData: data, lastMessageText: text) }
            catch { onError?(error.localizedDescription) }
        }
    }

    func sendImage(_ data: Data, completion: @escaping () -> Void) {
        Task {
            do {
                let urlString = try await service.uploadChatImage(data: data, chatId: chatId)
                
                let messageData: [String: Any] = [
                    "senderId": currentUser.senderId,
                    "senderName": currentUser.displayName,
                    "sentDate": FieldValue.serverTimestamp(),
                    "imageUrl": urlString
                ]
                
                try await service.sendMessage(chatId: chatId,
                                              otherUser: otherUser,
                                              messageData: messageData,
                                              lastMessageText: "Sent a photo")
                
                await MainActor.run { completion() }
                
            } catch {
                print("Error uploading image: \(error)")
                await MainActor.run { completion() }
            }
        }
    }

    deinit { listener?.remove() }
}
