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
import MessageKit // Required for MessageKit models

// MARK: - ChatViewModel

/// The ViewModel responsible for handling real-time message updates and sending content to Firestore.
/// Updated with Pagination to reduce Firebase read costs and improve performance.
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

    // MARK: - Pagination Properties

    /// Keeps track of the oldest document fetched to know where to start the next batch.
    private var oldestDocument: DocumentSnapshot?

    /// Flag to check if there are more messages left to load from the server.
    var hasMoreMessages = true

    /// Prevents multiple simultaneous network requests.
    private var isFetching = false

    /// Number of messages to fetch per request.
    private let messagesLimit = 20

    // Callbacks to notify the ViewController about data changes or errors.
    var onMessagesUpdated: ((_ isInitialLoad: Bool) -> Void)?
    var onOlderMessagesLoaded: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Initializer

    init(chatId: String, otherUser: ChatUser) {
        self.chatId = chatId
        self.otherUser = otherUser
    }

    // MARK: - Message Parsing Helper

    /// Converts a Firestore document into a MessageKit compatible 'Message' object.
    private func parseMessage(from doc: QueryDocumentSnapshot) -> Message? {
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
                size: CGSize(width: 240, height: 240) // Note: Consider calculating actual aspect ratio in future
            )
            return Message(sender: sender, messageId: doc.documentID, sentDate: sentDate, kind: .photo(media))
        }

        return nil
    }

    // MARK: - Pagination & Real-time Logic

    /// 1. Fetches the initial batch of the most recent messages when the chat is opened.
    func loadInitialMessages() {
        // We order by descending so we get the absolute newest messages first.
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: true)
            .limit(to: messagesLimit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.onError?(error.localizedDescription)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                // If we got fewer documents than our limit, there are no older messages.
                if docs.count < self.messagesLimit {
                    self.hasMoreMessages = false
                }

                // Save the last document (which is the oldest in time) for the next pagination query.
                self.oldestDocument = docs.last

                var initialMessages = [Message]()
                for doc in docs {
                    if let msg = self.parseMessage(from: doc) {
                        initialMessages.append(msg)
                    }
                }

                // Reverse the array because MessageKit displays oldest at the top, newest at the bottom.
                self.messages = initialMessages.reversed()

                // Notify UI that initial load is complete.
                self.onMessagesUpdated?(true)

                // 2. Setup real-time listener ONLY for new messages arriving after the newest message we just fetched.
                let lastDate = self.messages.last?.sentDate ?? Date()
                self.setupRealtimeListener(after: lastDate)
            }
    }

    /// Fetches older messages when the user taps the "Load Older" button.
    func loadOlderMessages() {
        // Prevent fetching if we are already fetching, or if there are no more messages.
        guard hasMoreMessages, !isFetching, let oldestDoc = oldestDocument else { return }
        isFetching = true

        db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: true)
            .start(afterDocument: oldestDoc) // Start exactly where we left off
            .limit(to: messagesLimit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                defer { self.isFetching = false } // Ensure fetching flag is reset

                if let error = error {
                    self.onError?(error.localizedDescription)
                    return
                }

                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    self.hasMoreMessages = false
                    self.onOlderMessagesLoaded?()
                    return
                }

                if docs.count < self.messagesLimit {
                    self.hasMoreMessages = false
                }
                self.oldestDocument = docs.last

                var olderMessages = [Message]()
                for doc in docs {
                    if let msg = self.parseMessage(from: doc) {
                        olderMessages.append(msg)
                    }
                }

                // Insert the newly fetched older messages at the TOP (index 0) of our array.
                self.messages.insert(contentsOf: olderMessages.reversed(), at: 0)

                // Notify UI to reload while maintaining scroll position.
                self.onOlderMessagesLoaded?()
            }
    }

    /// Establishes a real-time connection to Firestore to listen ONLY for newly sent messages.
    private func setupRealtimeListener(after date: Date) {
        let timestamp = Timestamp(date: date)

        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "sentDate", descending: false)
            .whereField("sentDate", isGreaterThan: timestamp) // Only listen to future messages
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else {
                    if let error = error { self?.onError?(error.localizedDescription) }
                    return
                }

                var newMessages = [Message]()
                for doc in docs {
                    // Prevent duplicate messages in case of local cache writes
                    if !self.messages.contains(where: { $0.messageId == doc.documentID }) {
                        if let msg = self.parseMessage(from: doc) {
                            newMessages.append(msg)
                        }
                    }
                }

                if !newMessages.isEmpty {
                    self.messages.append(contentsOf: newMessages)
                    self.onMessagesUpdated?(false) // false indicates this is a real-time update, not initial load
                }
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
                // Step 1: Upload the physical image file to Cloudinary.
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
