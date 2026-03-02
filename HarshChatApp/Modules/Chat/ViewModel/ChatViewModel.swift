//
//  ChatViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import MessageKit

// MARK: - ChatViewModel

/// The ViewModel responsible for handling real-time message updates and sending content to Firestore.
final class ChatViewModel {
    // MARK: - Properties

    private let service = ChatService()
    private let db = Firestore.firestore()

    let chatId: String
    let otherUser: ChatUser

    // Listener for real-time Firestore updates.
    private var listener: ListenerRegistration?

    /// Information about the person currently using the app.
    let currentUser = ChatUser(
        senderId: Auth.auth().currentUser?.uid ?? "",
        displayName: "Me", // You can fetch actual name from UserDefaults or Firestore profile
        phoneNumber: Auth.auth().currentUser?.phoneNumber ?? ""
    )

    // Array to hold all messages for the current chat session.
    var messages = [Message]()

    // Callbacks to notify the ViewController about data changes or errors.
    var onMessagesUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Initializer

    init(chatId: String, otherUser: ChatUser) {
        self.chatId = chatId
        self.otherUser = otherUser
    }

    // MARK: - Real-time Database Logic

    /// Establishes a real-time connection to Firestore to listen for new messages.
    func listenForMessages() {
        // Querying the 'messages' sub-collection inside a specific 'chat' document.
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: false) // Keeps messages in chronological order.
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.onError?(error?.localizedDescription ?? "Unknown error")
                    return
                }

                // Parsing Firestore documents into 'Message' objects.
                self.messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String ?? ""
                    let senderName = data["senderName"] as? String ?? ""
                    let sentDate = (data["sentDate"] as? Timestamp)?.dateValue() ?? Date()

                    // Create a dummy sender object for the message bubble.
                    let sender = ChatUser(senderId: senderId, displayName: senderName, phoneNumber: "")

                    // 1. Handle Text Messages
                    if let text = data["text"] as? String {
                        return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .text(text))
                    }
                    // 2. Handle Image Messages
                    else if let imageUrl = data["imageUrl"] as? String, let url = URL(string: imageUrl) {
                        let media = ImageMediaItem(
                            url: url,
                            image: nil,
                            placeholderImage: UIImage(systemName: "photo")!,
                            size: CGSize(width: 240, height: 240)
                        )
                        return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .photo(media))
                    }
                    return nil
                }

                // Notify the View Controller to reload the collection view.
                self.onMessagesUpdated?()
            }
    }

    // MARK: - Send Logic

    /// Sends a plain text message to Firestore.
    func sendText(_ text: String) {
        let data: [String: Any] = [
            "senderId": currentUser.senderId,
            "senderName": currentUser.displayName,
            "sentDate": FieldValue.serverTimestamp(), // Using server time for consistency.
            "text": text,
        ]

        // Task block handles the 'async' call to the service.
        Task {
            do {
                try await service.sendMessage(chatId: chatId, otherUser: otherUser, messageData: data, lastMessageText: text)
            } catch {
                onError?(error.localizedDescription)
            }
        }
    }

    /// Uploads an image to Storage and then saves the message to Firestore.
    func sendImage(_ data: Data, completion: @escaping () -> Void) {
        Task {
            do {
                // Step 1: Upload the physical image file to Firebase Storage.
                let urlString = try await service.uploadChatImage(data: data, chatId: chatId)

                // Step 2: Prepare the Firestore document with the image URL.
                let messageData: [String: Any] = [
                    "senderId": currentUser.senderId,
                    "senderName": currentUser.displayName,
                    "sentDate": FieldValue.serverTimestamp(),
                    "imageUrl": urlString,
                ]

                // Step 3: Save the message and update the 'Last Message' preview in conversation list.
                try await service.sendMessage(
                    chatId: chatId,
                    otherUser: otherUser,
                    messageData: messageData,
                    lastMessageText: "Sent a photo"
                )

                // Switch back to Main thread to update UI (stop loaders, etc).
                await MainActor.run { completion() }

            } catch {
                print("Error uploading image: \(error)")
                await MainActor.run { completion() }
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        // Crucial: Stop listening to Firestore when this chat screen is closed to save battery and data.
        listener?.remove()
    }
}
