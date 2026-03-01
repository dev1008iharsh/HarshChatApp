import FirebaseAuth
import FirebaseFirestore
import Foundation

final class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    private init() {}

    func sendOTP(phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { vID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let vID = vID else { return }
                continuation.resume(returning: vID)
            }
        }
    }

    func verifyCredential(verificationID: String, code: String) async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        return try await Auth.auth().signIn(with: credential)
    }

    func createNewUser(user: User) async throws {
        debugPrint("AuthService: Creating user in Firestore...")
        try db.collection("users").document(user.uid).setData(from: user, merge: true)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
