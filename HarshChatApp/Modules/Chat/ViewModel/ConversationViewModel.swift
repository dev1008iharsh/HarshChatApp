//
//  ConversationViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

final class ConversationViewModel {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private var listener: ListenerRegistration?

    var conversations = [Conversation]()
    var onDataUpdate: (() -> Void)?

    /// Sets up a real-time listener to fetch the list of active conversations for the current user.
    func fetchConversations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users").document(uid).collection("conversations")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }

                self.conversations = documents.map { doc -> Conversation in
                    let data = doc.data()
                    return Conversation(
                        id: doc.documentID,
                        otherUserName: data["otherUserName"] as? String ?? "User",
                        otherUserId: data["otherUserId"] as? String ?? "",
                        otherUserPhone: data["otherUserPhone"] as? String ?? "",
                        lastMessage: data["lastMessage"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        profileImageUrl: data["profileImageUrl"] as? String
                    )
                }
                self.onDataUpdate?()
            }
    }

    /// Orchestrates the deletion of a conversation from the UI, Firestore, and Firebase Storage.
    func deleteConversation(at index: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let conversationId = conversations[index].id

        // MAJOR EVENT: Removing the pointer from the user's personal chat list
        db.collection("users").document(uid).collection("conversations").document(conversationId).delete { [weak self] error in
            if let error = error {
                print("❌ DEBUG: Failed to delete conversation link: \(error.localizedDescription)")
                return
            }

            print("📱 DEBUG: Conversation removed from UI list for Chat: \(conversationId)")

            // Start background cleanup for actual messages and files
            Task {
                await self?.performFullCleanup(chatId: conversationId)
            }
        }
    }

    /// Handles the permanent removal of message documents and binary storage files.
    private func performFullCleanup(chatId: String) async {
        // 1. CLEANUP FIRESTORE MESSAGES
        let messagesRef = db.collection("chats").document(chatId).collection("messages")

        do {
            let snapshot = try await messagesRef.getDocuments()
            let batch = db.batch()

            // Queue each message for deletion
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }

            // Queue the parent chat document for deletion
            batch.deleteDocument(db.collection("chats").document(chatId))

            // MAJOR EVENT: Commit the deletion batch to Firestore
            try await batch.commit()
            print("✅ DEBUG: Firestore messages wiped for Chat: \(chatId)")

            // 2. CLEANUP STORAGE MEDIA
            // Path: chat_images/{chatId}/
            let folderRef = storage.child("chat_images/\(chatId)")

            // Fetch list of all files in this specific chat folder
            let listResult = try await folderRef.listAll()

            // Delete each file individually
            for item in listResult.items {
                try await item.delete()
            }

            // MAJOR EVENT: Final storage folder cleanup confirmation
            if !listResult.items.isEmpty {
                print("✅ DEBUG: Storage media files deleted for Chat: \(chatId)")
            }

        } catch {
            print("⚠️ DEBUG: Partial cleanup or folder not found for: \(chatId). Error: \(error.localizedDescription)")
        }
    }

    deinit {
        // Stop listening to Firestore updates when the ViewModel is destroyed
        listener?.remove()
    }
}
