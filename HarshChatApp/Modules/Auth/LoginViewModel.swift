//
//  LoginViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import FirebaseAuth
import Foundation

// MARK: - LoginViewModel

/// Handles authentication logic and manages the state for LoginViewController.
final class LoginViewModel {
    // MARK: - Callbacks

    var onStateChange: ((Bool) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String?) -> Void)?
    var onSuccess: (() -> Void)?

    // MARK: - State Properties

    private(set) var isOTPSent = false { didSet { onStateChange?(isOTPSent) } }
    private(set) var isLoading = false { didSet { onLoading?(isLoading) } }
    var errorMessage: String? { didSet { onError?(errorMessage) } }

    private var verificationID: String?

    // MARK: - Public Actions

    /// Decides whether to request OTP or verify based on current state.
    func handleMainButtonAction(phoneNumber: String, otpCode: String) {
        Task {
            if isOTPSent {
                await verifyOTP(code: otpCode)
            } else {
                await startVerification(phone: phoneNumber)
            }
        }
    }

    // MARK: - Private Logic

    @MainActor
    /// Requests Firebase to send an OTP to the given phone number.
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
            print("📩 [Debug] Auth: OTP Sent successfully.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    /// Verifies the OTP code and creates a user profile if they are new.
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

            // Create Firestore profile only for brand new users
            if result.additionalUserInfo?.isNewUser == true {
                print("👤 [Debug] Auth: New user detected. Creating Firestore profile.")
                let newUser = User(uid: result.user.uid, phoneNumber: result.user.phoneNumber ?? "")
                try await AuthService.shared.createNewUser(user: newUser)
            }

            print("✅ [Debug] Auth: Success! Navigating to Home.")
            onSuccess?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
