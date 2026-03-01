import FirebaseAuth
import Foundation

final class LoginViewModel {
    var onStateChange: ((Bool) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String?) -> Void)?
    var onSuccess: (() -> Void)?

    private(set) var isOTPSent = false { didSet { onStateChange?(isOTPSent) } }
    private(set) var isLoading = false { didSet { onLoading?(isLoading) } }
    var errorMessage: String? { didSet { onError?(errorMessage) } }
    
    private var verificationID: String?

    func handleMainButtonAction(phoneNumber: String, otpCode: String) {
        Task {
            if isOTPSent {
                await verifyOTP(code: otpCode)
            } else {
                await startVerification(phone: phoneNumber)
            }
        }
    }

    @MainActor
    private func startVerification(phone: String) async {
        guard phone.count == 13, phone.hasPrefix("+91") else {
            errorMessage = "Please enter a valid 10-digit mobile number."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            verificationID = try await AuthService.shared.sendOTP(phoneNumber: phone)
            isOTPSent = true
            debugPrint("LoginViewModel: OTP Sent successfully.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func verifyOTP(code: String) async {
        guard let vID = verificationID, code.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await AuthService.shared.verifyCredential(verificationID: vID, code: code)
            
            if result.additionalUserInfo?.isNewUser == true {
                let newUser = User(uid: result.user.uid, phoneNumber: result.user.phoneNumber ?? "")
                try await AuthService.shared.createNewUser(user: newUser)
                debugPrint("LoginViewModel: New user profile created.")
            }
            
            onSuccess?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
