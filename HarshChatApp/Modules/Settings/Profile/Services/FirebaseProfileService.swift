//
//  FirebaseProfileService.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import Cloudinary
import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

final class FirebaseProfileService {
    // Singleton instance
    static let shared = FirebaseProfileService()

    private let db = Firestore.firestore()

    private init() {}

    /// Updates user profile details and handles profile image upload to Cloudinary.
    /// Uses 0.1 compression to save storage and bandwidth.
    func updateProfile(uid: String, name: String, bio: String, email: String, gender: String, imageData: Data?) async throws {
        // Final dictionary to save in Firestore
        var userData: [String: Any] = [
            "name": name,
            "bio": bio,
            "email": email,
            "gender": gender,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        // 1. MAJOR EVENT: Handle Profile Image Upload
        if let data = imageData {
            print("🚀 DEBUG: Preparing Cloudinary profile upload for UID: \(uid)")

            // ✅ Image Compression (0.1 quality)
            guard let image = UIImage(data: data),
                  let compressedData = image.jpegData(compressionQuality: 0.1) else {
                print("❌ DEBUG: Profile compression failed.")
                throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress profile image"])
            }

            // ✅ Safe access to MainActor-isolated Cloudinary uploader
            let uploader = await MainActor.run {
                AppDelegate.cloudinary.createUploader()
            }

            // Cloudinary folder path
            let folderPath = "profile_images"

            // Uploading using Async/Await wrapper
            let profileURL: String = try await withCheckedThrowingContinuation { continuation in
                let params = CLDUploadRequestParams()
                params.setFolder(folderPath)

                // 💡 SENIOR TIP: Removing setPublicId and setOverwrite to avoid 400 Error
                // in Unsigned Presets. Cloudinary will auto-generate a unique filename.

                uploader.upload(
                    data: compressedData,
                    uploadPreset: "chat_app_preset", // ⚠️ Ensure this is Unsigned
                    params: params,
                    progress: { progress in
                        let percent = Int(progress.fractionCompleted * 100)
                        print("⏳ Profile Image Uploading: \(percent)%")
                    }
                ) { result, error in
                    if let error = error {
                        print("❌ DEBUG: Cloudinary Upload Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }

                    if let url = result?.secureUrl {
                        continuation.resume(returning: url)
                    } else {
                        let unknownError = NSError(domain: "Cloudinary", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve secure URL"])
                        continuation.resume(throwing: unknownError)
                    }
                }
            }

            // Add the new URL to Firestore data
            userData["profileImageUrl"] = profileURL
            print("✅ DEBUG: Profile image synced: \(profileURL)")
        }

        // 2. MAJOR EVENT: Update Firestore
        print("📱 DEBUG: Finalizing Firestore update for UID: \(uid)")

        do {
            try await db.collection("users").document(uid).setData(userData, merge: true)
            print("🎉 DEBUG: Profile updated successfully in Firestore.")
        } catch {
            print("❌ DEBUG: Firestore update failed: \(error.localizedDescription)")
            throw error
        }
    }
}

/*
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
 */
