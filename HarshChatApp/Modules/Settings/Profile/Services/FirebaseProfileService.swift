//
//  FirebaseProfileService.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

final class FirebaseProfileService {
    static let shared = FirebaseProfileService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    private init() {}

    /// Updates user profile details and handles profile image upload to Firebase Storage.
    func updateProfile(uid: String, name: String, bio: String, email: String, gender: String, imageData: Data?) async throws {
        var userData: [String: Any] = [
            "name": name,
            "bio": bio,
            "email": email,
            "gender": gender,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        // MAJOR EVENT: Handle Profile Image Upload if data is provided
        if let data = imageData {
            print("DEBUG: Starting profile image upload for UID: \(uid)")

            let imageRef = storage.child("profile_images/\(uid).jpg")

            // Uploading data to Firebase Storage
            _ = try await imageRef.putDataAsync(data)

            // Retrieving the downloadable URL
            let url = try await imageRef.downloadURL()
            userData["profileImageUrl"] = url.absoluteString

            print("DEBUG: Image uploaded successfully. URL: \(url.absoluteString)")
        }

        // MAJOR EVENT: Save or Merge user data into Firestore
        print("DEBUG: Updating Firestore document for UID: \(uid)")
        try await db.collection("users").document(uid).setData(userData, merge: true)
    }
}
