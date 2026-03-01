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
        
        // ✅ Real-time Listener
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
                        otherUserPhone: data["otherUserPhone"] as? String ?? "",
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
        let conversationId = conversations[index].id
        
        // ✅ 1. Remove the conversation entry from the user's list
        db.collection("users").document(uid).collection("conversations").document(conversationId).delete { [weak self] error in
            if let error = error {
                print("Error deleting conversation link: \(error.localizedDescription)")
                return
            }
            
            // ✅ 2. Now clean up all messages from the main messages collection
            self?.deleteAllMessagesFromFirebase(conversationId: conversationId)
        }
    }
    
    private func deleteAllMessagesFromFirebase(conversationId: String) {
        // Assuming your messages are in a sub-collection under the conversation
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        messagesRef.getDocuments { [weak self] (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else { return }
            
            // ✅ Using Write Batch for better performance (upto 500 docs at once)
            let batch = self?.db.batch()
            
            documents.forEach { doc in
                batch?.deleteDocument(doc.reference)
            }
            
            // Also delete the main conversation document if it exists
            batch?.deleteDocument(self?.db.collection("conversations").document(conversationId) ?? Firestore.firestore().collection("conversations").document(conversationId))
            
            batch?.commit { error in
                if let error = error {
                    print("Error performing batch delete: \(error.localizedDescription)")
                } else {
                    print("Successfully wiped out everything for conversation: \(conversationId)")
                }
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
