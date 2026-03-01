//
//  LoginViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import Foundation
import FirebaseAuth

// MARK: - Login Coordinator Protocol
/// Protocol to communicate back to the Coordinator
protocol LoginCoordinatorProtocol: AnyObject {
    func didFinishAuth()
}

final class LoginViewModel {
    
    // MARK: - Properties
    weak var coordinator: LoginCoordinatorProtocol?
    
    // MARK: - Observables (UI Binding)
    /// Controls whether to show Phone input or OTP input
    var isOTPSent: Bool = false {
        didSet { onStateChange?(isOTPSent) }
    }
    
    /// Controls the activity indicator state
    var isLoading: Bool = false {
        didSet { onLoading?(isLoading) }
    }
    
    /// Passes error messages to show in the UI
    var errorMessage: String? {
        didSet { onError?(errorMessage) }
    }
    
    // MARK: - Callbacks
    var onStateChange: ((Bool) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String?) -> Void)?
    
    /// Stores the Firebase verification ID (Safe Optional)
    private var verificationID: String?
    
    // MARK: - Main Actions
    
    /// Handles the primary button click logic
    /// Handles the primary button click logic with specific validation messages
    func handleMainButtonAction(phoneNumber: String?, otpCode: String?) {
        if !isOTPSent {
            // 1. Phone number validation logic
            guard let phone = phoneNumber, phone.count == 13 else {
                // Notifies UI to show alert for incomplete phone number
                self.onError?("Please enter your 10-digit mobile number to continue.")
                return
            }
            
            guard phone.hasPrefix("+91") else {
                // Notifies UI for invalid country code prefix
                self.onError?("Invalid country code. Please use a valid number.")
                return
            }
            
            startVerification(phone: phone)
        } else {
            // 2. OTP validation logic for secure login
            guard let otp = otpCode, otp.count == 6 else {
                // Notifies UI to show alert for invalid OTP length
                self.onError?("The OTP must be 6 digits. Please check and try again.")
                return
            }
            
            verifyOTP(code: otp)
        }
    }
    
    // MARK: - Firebase Logic
    
    /// Requests OTP from Firebase
    private func startVerification(phone: String) {
        isLoading = true
        
        // 2026 Best Practice: Using modern closure-based verification
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { [weak self] vID, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                // Handling Firebase errors (like too many requests)
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Safe check to avoid nil unwrapping crash
            guard let vID = vID else {
                self.errorMessage = "Failed to get Verification ID from Firebase."
                return
            }
            
            self.verificationID = vID
            self.isOTPSent = true
            print("✅ Success: OTP sent. vID: \(vID)")
        }
    }
    
    /// Verifies OTP with Firebase and signs the user in
    private func verifyOTP(code: String) {
        guard let vID = verificationID else {
            self.errorMessage = "Session expired. Please try sending OTP again."
            self.isOTPSent = false
            return
        }
        
        isLoading = true
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: vID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Authentication Success
            print("✅ Success: User signed in successfully!")
            self.coordinator?.didFinishAuth()
        }
    }
}
