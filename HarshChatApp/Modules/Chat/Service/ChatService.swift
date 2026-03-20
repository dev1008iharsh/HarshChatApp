//
//  ChatService.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import Cloudinary
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

// MARK: - ChatService

final class ChatService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()

    // MARK: - Message Operations

    /// Sends a message and updates conversation summaries for both users using Async/Await.
    /// Refined with Firestore Write Batches for atomicity.
    func sendMessage(chatId: String, otherUser: ChatUser, messageData: [String: Any], lastMessageText: String) async throws {
        // MAJOR EVENT: Validating current authentication session
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentPhone = Auth.auth().currentUser?.phoneNumber else {
            print("DEBUG: ChatService - Authentication failed or session expired.")
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        // ✅ FIX 1: Fetch Current User's actual Name and Profile Image from Firestore 'users' collection

        let currentUserDoc = try await db.collection("users").document(currentUid).getDocument()
        let currentUserName = currentUserDoc.data()?["name"] as? String ?? currentPhone // જો નામ ના હોય તો નંબર બતાવશે
        let currentUserImage = currentUserDoc.data()?["profileImageUrl"] as? String ?? ""

        // ✅ CRITICAL IMPROVEMENT: Using Firestore Batch to ensure all or nothing updates.
        let batch = db.batch()

        // 1. MAJOR EVENT: Adding the actual message to the sub-collection
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()
        batch.setData(messageData, forDocument: messageRef)

        // 2. MAJOR EVENT: Updating My (Sender) Conversation List
        let myConversationRef = db.collection("users").document(currentUid).collection("conversations").document(chatId)
        let myConversationData: [String: Any] = [
            "otherUserName": otherUser.displayName,
            "otherUserId": otherUser.senderId,
            "otherUserPhone": otherUser.phoneNumber,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": otherUser.profileImageUrl ?? "",
        ]
        batch.setData(myConversationData, forDocument: myConversationRef, merge: true)

        // 3. MAJOR EVENT: Updating Their (Receiver) Conversation List
        let otherConversationRef = db.collection("users").document(otherUser.senderId).collection("conversations").document(chatId)
        let otherConversationData: [String: Any] = [
            "otherUserName": currentUserName,
            "otherUserId": currentUid,
            "otherUserPhone": currentPhone,
            "lastMessage": lastMessageText,
            "timestamp": FieldValue.serverTimestamp(),
            "profileImageUrl": currentUserImage,
        ]
        batch.setData(otherConversationData, forDocument: otherConversationRef, merge: true)

        // ✅ Commit the batch
        try await batch.commit()

        print("DEBUG: ChatService - Message and conversations synced successfully using Batch.")
    }

    // MARK: - Media Operations

    /*
     /// Uploads an image to Google Firebase Storage and returns the downloadable URL.
     func uploadChatImage(data: Data, chatId: String) async throws -> String {
         // MAJOR EVENT: Creating unique filename and path
         let fileName = UUID().uuidString
         let imageRef = storage.child("chat_images/\(chatId)/\(fileName).jpg")

         let metadata = StorageMetadata()
         metadata.contentType = "image/jpeg"

         print("DEBUG: ChatService - Starting image upload for Chat: \(chatId)")

         // Put data into storage using async method
         _ = try await imageRef.putDataAsync(data, metadata: metadata)

         // Retrieve the public URL
         let downloadURL = try await imageRef.downloadURL()

         print("DEBUG: ChatService - Image upload success. URL: \(downloadURL.absoluteString)")
         return downloadURL.absoluteString
     }
     */

    /// Uploads an image to Cloudinary with organized folder structure and unique filename.
    /// Format: all_user_chats/chatId/UUID.jpg
    func uploadChatImage(data: Data, chatId: String) async throws -> String {
        // 1. MAJOR EVENT: Image Compression to 0.1 (10% quality)
        guard let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: 0.1) else {
            print("❌ DEBUG: ChatService - Compression failed.")
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        print("🚀 DEBUG: ChatService - Starting Cloudinary upload for Chat: \(chatId)")

        // 2. MAJOR EVENT: Setup Organized Folder and Filename
        // Format: chat_images/YOUR_CHAT_ID/UNIQUE_ID
        let fileName = UUID().uuidString
        let folderPath = "chat_images/\(chatId)"

        // ✅ Accessing MainActor isolated property safely
        let uploader = await MainActor.run {
            AppDelegate.cloudinary.createUploader()
        }

        // 3. MAJOR EVENT: Cloudinary Upload
        return try await withCheckedThrowingContinuation { continuation in

            let params = CLDUploadRequestParams()
            params.setFolder(folderPath) // 📁 Organized by Chat ID
            params.setPublicId(fileName) // 📄 Unique Filename using UUID

            uploader.upload(
                data: compressedData,
                uploadPreset: "chat_app_preset", // ⚠️ Ensure this is Unsigned in Dashboard
                params: params,
                progress: { progress in
                    let percent = Int(progress.fractionCompleted * 100)
                    print("⏳ Uploading to Cloudinary [\(chatId)]: \(percent)%")
                }
            ) { result, error in

                if let error = error {
                    print("❌ DEBUG: ChatService - Cloudinary Error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                if let url = result?.secureUrl {
                    print("✅ DEBUG: ChatService - Upload Success. URL: \(url)")
                    continuation.resume(returning: url)
                } else {
                    let unknownError = NSError(domain: "Cloudinary", code: 0, userInfo: [NSLocalizedDescriptionKey: "Secure URL not found"])
                    continuation.resume(throwing: unknownError)
                }
            }
        }
    }
}
