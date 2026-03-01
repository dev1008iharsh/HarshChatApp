import Foundation
import FirebaseFirestore
import FirebaseAuth

final class NewChatViewModel {
    private let db = Firestore.firestore()
    var allContacts = [ContactModel]()
    var filteredContacts = [ContactModel]()
    var onDataLoaded: (() -> Void)?

    func loadAndCheckContacts() {
        ContactService.shared.fetchPhoneContacts { [weak self] phoneContacts in
            // Sort contacts alphabetically
            let sorted = phoneContacts.sorted { $0.firstName < $1.firstName }
            self?.allContacts = sorted
            self?.filteredContacts = sorted
            self?.onDataLoaded?()
        }
    }
    
    // ✅ Bug Fix: Improved User Search with +91 handling
    func searchUser(with number: String, completion: @escaping (ChatUser?) -> Void) {
        var fullNumber = number
        if !number.hasPrefix("+") {
            fullNumber = "+91\(number)"
        }
        
        db.collection("users").whereField("phoneNumber", isEqualTo: fullNumber).getDocuments { snapshot, _ in
            guard let doc = snapshot?.documents.first else {
                completion(nil)
                return
            }
            
            let data = doc.data()
            let user = ChatUser(
                senderId: doc.documentID,
                displayName: data["name"] as? String ?? "Unknown",
                phoneNumber: data["phoneNumber"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String
            )
            completion(user)
        }
    }
    
    func generateChatId(with otherUserUid: String) -> String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return "" }
        // Unique ID created by combining UIDs (Lexicographical order)
        return currentUid < otherUserUid ? "\(currentUid)_\(otherUserUid)" : "\(otherUserUid)_\(currentUid)"
    }
    
    func filterContacts(with text: String) {
        if text.isEmpty {
            filteredContacts = allContacts
        } else {
            filteredContacts = allContacts.filter {
                $0.firstName.lowercased().contains(text.lowercased()) ||
                $0.phoneNumber.contains(text)
            }
        }
        onDataLoaded?()
    }
}
