import FirebaseAuth
import Foundation

final class EditProfileViewModel {
    var name: String
    var bio: String
    var email: String
    let phone: String
    var gender: String
    var profileImageUrl: String?
    var profileImageData: Data?

    var onUpdateSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStatus: ((Bool) -> Void)?

    init(user: User) {
        self.name = user.name
        self.bio = user.bio
        self.email = user.email ?? ""
        self.phone = user.phoneNumber
        self.gender = user.gender
        self.profileImageUrl = user.profileImageUrl
    }

    @MainActor
    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            onError?("User not found")
            return
        }

        onLoadingStatus?(true)

        Task {
            do {
                try await FirebaseProfileService.shared.updateProfile(
                    uid: uid,
                    name: name,
                    bio: bio,
                    email: email,
                    gender: gender,
                    imageData: profileImageData
                )
                onLoadingStatus?(false)
                onUpdateSuccess?()
            } catch {
                onLoadingStatus?(false)
                onError?(error.localizedDescription)
            }
        }
    }
}
