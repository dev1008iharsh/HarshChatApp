import FirebaseFirestore
import FirebaseStorage
import Foundation

final class FirebaseProfileService {
    static let shared = FirebaseProfileService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    private init() {}

    /// Updates user profile including Bio and Profile Image
    func updateProfile(uid: String, name: String, bio: String, email: String, gender: String, imageData: Data?, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. Prepare initial user data dictionary
        var userData: [String: Any] = [
            "name": name,
            "bio": bio, // ✅ Your new bio field is correctly mapped here
            "email": email,
            "gender": gender,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        // 2. Check if we have a new image to upload
        if let data = imageData {
            let imageRef = storage.child("profile_images/\(uid).jpg")

            // Upload Image to Firebase Storage
            imageRef.putData(data, metadata: nil) { [weak self] _, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                // Get Download URL
                imageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let url = url else { return }

                    // Add Image URL to our dictionary
                    userData["profileImageUrl"] = url.absoluteString

                    // Final Save to Firestore
                    self?.saveToFirestore(uid: uid, data: userData, completion: completion)
                }
            }
        } else {
            // 3. If no image, just update the text fields (including Bio)
            saveToFirestore(uid: uid, data: userData, completion: completion)
        }
    }

    private func saveToFirestore(uid: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        // 'merge: true' ensures we don't overwrite existing fields like 'phoneNumber'
        db.collection("users").document(uid).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
