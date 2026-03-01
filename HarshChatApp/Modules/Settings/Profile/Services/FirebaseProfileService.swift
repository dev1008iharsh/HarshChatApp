import FirebaseFirestore
import FirebaseStorage
import Foundation

final class FirebaseProfileService {
    static let shared = FirebaseProfileService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    private init() {}

    func updateProfile(uid: String, name: String, bio: String, email: String, gender: String, imageData: Data?) async throws {
        var userData: [String: Any] = [
            "name": name,
            "bio": bio,
            "email": email,
            "gender": gender,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let data = imageData {
            let imageRef = storage.child("profile_images/\(uid).jpg")
            _ = try await imageRef.putDataAsync(data)
            let url = try await imageRef.downloadURL()
            userData["profileImageUrl"] = url.absoluteString
        }

        try await db.collection("users").document(uid).setData(userData, merge: true)
    }
}
