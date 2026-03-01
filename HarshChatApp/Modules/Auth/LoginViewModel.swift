//
//  LoginViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import FirebaseAuth
import Foundation

protocol LoginCoordinatorProtocol: AnyObject {
    func didFinishAuth()
}

final class LoginViewModel {
    weak var coordinator: LoginCoordinatorProtocol?

    var isOTPSent: Bool = false {
        didSet { onStateChange?(isOTPSent) }
    }

    var isLoading: Bool = false {
        didSet { onLoading?(isLoading) }
    }

    var errorMessage: String? {
        didSet { onError?(errorMessage) }
    }

    var onStateChange: ((Bool) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String?) -> Void)?

    private var verificationID: String?

    func handleMainButtonAction(phoneNumber: String?, otpCode: String?) {
        if !isOTPSent {
            guard let phone = phoneNumber, phone.count == 13 else {
                onError?("Please enter your 10-digit mobile number to continue.")
                return
            }

            guard phone.hasPrefix("+91") else {
                onError?("Invalid country code. Please use a valid number.")
                return
            }

            startVerification(phone: phone)
        } else {
            guard let otp = otpCode, otp.count == 6 else {
                onError?("The OTP must be 6 digits. Please check and try again.")
                return
            }

            verifyOTP(code: otp)
        }
    }

    private func startVerification(phone: String) {
        isLoading = true

        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { [weak self] vID, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let vID = vID else {
                self.errorMessage = "Failed to get Verification ID from Firebase."
                return
            }

            self.verificationID = vID
            self.isOTPSent = true
        }
    }

    private func verifyOTP(code: String) {
        guard let vID = verificationID else {
            errorMessage = "Session expired. Please try sending OTP again."
            isOTPSent = false
            return
        }

        isLoading = true

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: vID,
            verificationCode: code
        )

        Auth.auth().signIn(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            self.coordinator?.didFinishAuth()
        }
    }
}
