import FirebaseAuth
import FirebaseFirestore
import Foundation

final class SettingsViewModel {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var currentUser: User?
    var sections = [SettingsSection]()

    var onDataUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLogout: (() -> Void)?
    var onNavigateToEdit: ((User) -> Void)?
    var showAlert: ((String) -> Void)?

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener?.remove()

        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.onError?(error.localizedDescription)
                return
            }

            guard let data = snapshot?.data() else { return }

            var user = User(
                uid: uid,
                phoneNumber: data["phoneNumber"] as? String ?? "",
                name: data["name"] as? String ?? "User Name",
                bio: data["bio"] as? String ?? "Available"
            )
            user.profileImageUrl = data["profileImageUrl"] as? String
            user.email = data["email"] as? String
            user.gender = data["gender"] as? String ?? "Other"

            self.currentUser = user
            self.setupSections()
            self.onDataUpdate?()
        }
    }

    private func setupSections() {
        sections.removeAll()

        let profileOption = SettingsOption(
            title: currentUser?.name ?? "User",
            subtitle: currentUser?.bio,
            iconName: "person.fill",
            iconBackgroundColor: .systemGray5,
            iconTintColor: AppColor.primaryTeal,
            titleColor: AppColor.primaryText,
            isLogout: false
        ) { [weak self] in
            if let user = self?.currentUser {
                self?.onNavigateToEdit?(user)
            }
        }
        sections.append(SettingsSection(title: "Profile", options: [profileOption]))

        sections.append(
            SettingsSection(
                title: "App Settings",
                options: [
                    SettingsOption(title: "Account", subtitle: "Privacy, security", iconName: "key.fill", iconBackgroundColor: .systemBlue, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Account Settings") },
                    SettingsOption(title: "Chats", subtitle: "Theme, wallpapers", iconName: "message.fill", iconBackgroundColor: AppColor.primaryTeal, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Chat Settings") },
                    SettingsOption(title: "Notifications", subtitle: "Tones", iconName: "bell.badge.fill", iconBackgroundColor: .systemRed, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Notifications") },
                    SettingsOption(title: "Storage", subtitle: "Network usage", iconName: "chart.pie.fill", iconBackgroundColor: .systemGreen, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Storage and Data") }
                ]
            )
        )

        sections.append(SettingsSection(title: "Help", options: [
            SettingsOption(title: "Help Center", subtitle: "FAQ, contact us", iconName: "questionmark.circle.fill", iconBackgroundColor: .systemGray, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Help Center") },
            SettingsOption(title: "Invite a Friend", subtitle: nil, iconName: "person.2.fill", iconBackgroundColor: .systemPink, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Invite a Friend") }
        ]))

        sections.append(
            SettingsSection(
                title: "Actions",
                options: [
                    SettingsOption(title: "Delete Account", subtitle: "Permanently delete", iconName: "trash.fill", iconBackgroundColor: .systemRed, iconTintColor: .systemRed, titleColor: .systemRed, isLogout: true) { self.showAlert?("Delete Account") },
                    SettingsOption(title: "Log Out", subtitle: nil, iconName: "rectangle.portrait.and.arrow.right", iconBackgroundColor: .systemRed, iconTintColor: .systemRed, titleColor: .systemRed, isLogout: true) { [weak self] in
                        self?.performLogout()
                    }
                ]
            )
        )
    }

    private func performLogout() {
        do {
            try Auth.auth().signOut()
            onLogout?()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    deinit {
        listener?.remove()
    }
}
