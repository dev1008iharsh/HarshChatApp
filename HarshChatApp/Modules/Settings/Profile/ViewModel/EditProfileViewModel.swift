//
//  EditProfileViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseAuth
import Foundation

final class EditProfileViewModel {
    // MARK: - Properties

    var name: String
    var bio: String
    var email: String
    let phone: String
    var gender: String
    var profileImageUrl: String?
    var profileImageData: Data?

    // UI Binding Closures
    var onUpdateSuccess: (() -> Void)?
    var onError: ((String) -> Void)? // Changed to handle UI alerts easily
    var onLoadingStatus: ((Bool) -> Void)?

    // MARK: - Initializer

    init(user: User) {
        name = user.name
        bio = user.bio
        email = user.email ?? ""
        phone = user.phoneNumber
        gender = user.gender
        profileImageUrl = user.profileImageUrl
    }

    // MARK: - Logic

    @MainActor
    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("DEBUG: Auth Error - Current UID is nil")
            onError?("User not found")
            return
        }

        onLoadingStatus?(true)

        Task {
            do {
                // MAJOR EVENT: Calling Firebase service to update details and upload image
                try await FirebaseProfileService.shared.updateProfile(
                    uid: uid,
                    name: name,
                    bio: bio,
                    email: email,
                    gender: gender,
                    imageData: profileImageData
                )

                print("DEBUG: Profile update success for UID: \(uid)")
                onLoadingStatus?(false)
                onUpdateSuccess?()

            } catch {
                print("DEBUG: Profile update failed with error: \(error.localizedDescription)")
                onLoadingStatus?(false)
                // Passing error message back to UI

                self.onError?(error.localizedDescription) // If needed string
            }
        }
    }
}
