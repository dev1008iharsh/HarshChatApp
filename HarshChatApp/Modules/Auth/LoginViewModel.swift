import FirebaseAuth
import Foundation

final class LoginViewModel {
    // MARK: - Properties

    // ઇનપુટ સ્ટેટ મેનેજમેન્ટ માટેના ઓબ્ઝર્વેબલ્સ
    var isOTPSent: Bool = false {
        didSet { onStateChange?(isOTPSent) }
    }

    var isLoading: Bool = false {
        didSet { onLoading?(isLoading) }
    }

    var errorMessage: String? {
        didSet { onError?(errorMessage) }
    }

    // MARK: - Callbacks (Data Binding)

    // ViewController આ ક્લોઝર્સને બાઇન્ડ કરશે
    var onStateChange: ((Bool) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String?) -> Void)?
    var onSuccess: (() -> Void)?

    private var verificationID: String?

    // MARK: - Main Logic

    /// બટન ક્લિક પર ફોન વેરીફિકેશન અથવા OTP વેરીફિકેશન નક્કી કરશે
    func handleMainButtonAction(phoneNumber: String, otpCode: String) {
        Task {
            if !isOTPSent {
                await startVerification(phone: phoneNumber)
            } else {
                await verifyOTP(code: otpCode)
            }
        }
    }

    // MARK: - Private API Methods

    @MainActor
    private func startVerification(phone: String) async {
        // Validation: ભારતીય નંબર માટે +91 અને 10 આંકડા હોવા જરૂરી છે
        guard phone.count == 13, phone.hasPrefix("+91") else {
            errorMessage = "Please enter your 10-digit mobile number to continue."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Firebase OTP Send
            let vID = try await AuthService.shared.sendOTP(phoneNumber: phone)
            verificationID = vID
            isOTPSent = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func verifyOTP(code: String) async {
        // Validation: OTP હંમેશા 6 આંકડાનો હોવો જોઈએ
        guard let vID = verificationID, code.count == 6 else {
            errorMessage = "The OTP must be 6 digits."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Firebase Credential Verification
            let authResult = try await AuthService.shared.verifyCredential(verificationID: vID, code: code)

            // જો નવો યુઝર હોય, તો Firestore માં પ્રોફાઇલ ડેટા ક્રિએટ કરવો
            if authResult.additionalUserInfo?.isNewUser == true {
                let newUser = User(uid: authResult.user.uid, phoneNumber: authResult.user.phoneNumber ?? "")
                try await AuthService.shared.createNewUser(user: newUser)
            }

            isLoading = false
            // સફળતાપૂર્વક લોગિન થયા પછી આ કોલબેક ViewController ને જાણ કરશે
            onSuccess?()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
