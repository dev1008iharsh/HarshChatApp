//
//  AuthService.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - AuthService

/// Handles all Firebase Authentication and Firestore user management tasks.
final class AuthService {
    // MARK: - Properties

    static let shared = AuthService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Auth Methods

    /// Sends an OTP to the provided phone number and returns a Verification ID.
    func sendOTP(phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { vID, error in
                if let error = error {
                    print("❌ [Debug] Auth: OTP Send Failed - \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                guard let vID = vID else { return }
                print("📩 [Debug] Auth: OTP Sent. Verification ID received.")
                continuation.resume(returning: vID)
            }
        }
    }

    /// Verifies the OTP code and signs the user into Firebase.
    func verifyCredential(verificationID: String, code: String) async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        let result = try await Auth.auth().signIn(with: credential)
        print("✅ [Debug] Auth: User signed in successfully.")
        return result
    }

    /// Saves or updates the user profile data in Firestore.
    func createNewUser(user: User) async throws {
        print("💾 [Debug] Firestore: Saving user data for \(user.uid)")
        try db.collection("users").document(user.uid).setData(from: user, merge: true)
    }

    /// Logs the user out of the current Firebase session.
    func signOut() throws {
        try Auth.auth().signOut()
        print("🚪 [Debug] Auth: User logged out.")
    }
}
