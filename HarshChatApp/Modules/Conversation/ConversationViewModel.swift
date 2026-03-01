//
//  ConversationViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ConversationViewModel {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    var conversations = [Conversation]()
    var onDataUpdate: (() -> Void)?
    
    func fetchConversations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users").document(uid).collection("conversations")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                self.conversations = documents.map { doc -> Conversation in
                    let data = doc.data()
                    return Conversation(
                        id: doc.documentID,
                        otherUserName: data["otherUserName"] as? String ?? "User",
                        otherUserId: data["otherUserId"] as? String ?? "",
                        lastMessage: data["lastMessage"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        profileImageUrl: data["profileImageUrl"] as? String
                    )
                }
                self.onDataUpdate?()
            }
    }
    
    func deleteConversation(at index: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let id = conversations[index].id
        db.collection("users").document(uid).collection("conversations").document(id).delete()
    }
    
    deinit { listener?.remove() }
}
