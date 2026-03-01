import FirebaseAuth
import Foundation

final class EditProfileViewModel {
    // UI Binding Variables
    var name: String
    var bio: String
    var email: String
    let phone: String
    var gender: String
    var profileImageUrl: String?
    var profileImageData: Data? // For New Image Upload

    var onUpdateSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStatus: ((Bool) -> Void)?

    // ✅ Professional Init: Taking entire User model
    init(user: User) {
        name = user.name
        bio = user.bio
        email = user.email ?? ""
        phone = user.phoneNumber
        gender = user.gender
        profileImageUrl = user.profileImageUrl
    }

    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        onLoadingStatus?(true)

        // Calling Service to update Firebase
        FirebaseProfileService.shared.updateProfile(
            uid: uid,
            name: name,
            bio: bio,
            email: email,
            gender: gender,
            imageData: profileImageData
        ) { [weak self] result in
            self?.onLoadingStatus?(false)
            switch result {
            case .success:
                self?.onUpdateSuccess?()
            case let .failure(error):
                self?.onError?(error.localizedDescription)
            }
        }
    }
}
