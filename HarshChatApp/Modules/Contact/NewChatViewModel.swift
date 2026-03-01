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
            self?.allContacts = phoneContacts
            self?.filteredContacts = phoneContacts
            self?.onDataLoaded?()
        }
    }
    
    func searchUser(with number: String, completion: @escaping (User?) -> Void) {
        let fullNumber = "+91\(number)"
        
        db.collection("users").whereField("phoneNumber", isEqualTo: fullNumber).getDocuments { snapshot, _ in
            guard let doc = snapshot?.documents.first else {
                completion(nil)
                return
            }
            
            let data = doc.data()
            let user = User(
                uid: doc.documentID,
                phoneNumber: data["phoneNumber"] as? String ?? "",
                name: data["name"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String
            )
            completion(user)
        }
    }
    
    func generateChatId(with otherUserUid: String) -> String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return "" }
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
