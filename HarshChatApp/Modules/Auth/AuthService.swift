import FirebaseAuth
import FirebaseFirestore
import Foundation

final class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()

    private init() {}

    func sendOTP(phoneNumber: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let vID = verificationID {
                    continuation.resume(returning: vID)
                }
            }
        }
    }

    func verifyCredential(verificationID: String, code: String) async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        return try await Auth.auth().signIn(with: credential)
    }

    func createNewUser(user: User) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "phoneNumber": user.phoneNumber,
            "name": user.name,
            "bio": user.bio,
            "profileImageUrl": user.profileImageUrl ?? "",
            "gender": user.gender,
            "createdAt": user.createdAt,
        ]
        try await db.collection("users").document(user.uid).setData(userData, merge: true)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
