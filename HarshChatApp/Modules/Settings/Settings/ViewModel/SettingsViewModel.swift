import FirebaseAuth
import FirebaseFirestore
import Foundation

final class SettingsViewModel {
    // MARK: - Properties

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var currentUser: User?
    var sections = [SettingsSection]()

    // MARK: - Callbacks for UI Update

    var onDataUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLogout: (() -> Void)?
    var onNavigateToEdit: ((User) -> Void)?
    var showAlert: ((String) -> Void)?

    // MARK: - Fetch Data with Real-time Listener

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // જો પહેલાથી કોઈ લિસનર ચાલુ હોય તો તેને રિમૂવ કરવો (Best Practice)
        listener?.remove()

        // Firebase Real-time Listener 🛰️
        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.onError?(error.localizedDescription)
                return
            }

            guard let data = snapshot?.data() else { return }

            // Mapping Firebase Data to User Model
            let user = User(
                uid: uid,
                phoneNumber: data["phoneNumber"] as? String ?? "",
                name: data["name"] as? String ?? "User Name",
                bio: data["bio"] as? String ?? "Available"
            )
            // Optional fields
            var updatedUser = user
            updatedUser.profileImageUrl = data["profileImageUrl"] as? String
            updatedUser.email = data["email"] as? String
            updatedUser.gender = data["gender"] as? String ?? "Other"

            self.currentUser = updatedUser

            // સેક્શન ફરીથી સેટ કરવા જેથી નવો ડેટા દેખાય
            self.setupSections()

            // View Controller ને જાણ કરવી કે ડેટા આવી ગયો છે
            self.onDataUpdate?()
        }
    }

    // MARK: - Setup TableView Sections

    private func setupSections() {
        sections.removeAll()

        // 1. Profile Section (Dynamic Data)
        let profileOption = SettingsOption(
            title: currentUser?.name ?? "Harsh Patel",
            subtitle: currentUser?.bio, // ✅ This is your Bio
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

        // 2. App Settings Section
        sections.append(
            SettingsSection(
                title: "App Settings",
                options: [
                    SettingsOption(
                        title: "Account",
                        subtitle: "Privacy, security, change number",
                        iconName: "key.fill",
                        iconBackgroundColor: .systemBlue,
                        iconTintColor: .label,
                        titleColor: AppColor.primaryText,
                        isLogout: false
                    ) {
                        self.showAlert?("Account Settings")
                    },
                    SettingsOption(title: "Chats", subtitle: "Theme, wallpapers, chat history", iconName: "message.fill", iconBackgroundColor: AppColor.primaryTeal, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Chat Settings") },
                    SettingsOption(title: "Notifications", subtitle: "Message, group & call tones", iconName: "bell.badge.fill", iconBackgroundColor: .systemRed, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Notifications") },
                    SettingsOption(title: "Storage and Data", subtitle: "Network usage, auto-download", iconName: "chart.pie.fill", iconBackgroundColor: .systemGreen, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Storage and Data") },
                ]
            )
        )

        // 3. Support & Help
        sections.append(SettingsSection(title: "Help", options: [
            SettingsOption(title: "Help Center", subtitle: "FAQ, contact us, privacy policy", iconName: "questionmark.circle.fill", iconBackgroundColor: .systemGray, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Help Center") },
            SettingsOption(title: "Invite a Friend", subtitle: nil, iconName: "person.2.fill", iconBackgroundColor: .systemPink, iconTintColor: .label, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Invite a Friend") },
        ]))

        // 4. Danger Zone (Actions)
        sections.append(
            SettingsSection(
                title: "Actions",
                options: [
                    SettingsOption(
                        title: "Delete Account",
                        subtitle: "Permanently delete your account",
                        iconName: "trash.fill",
                        iconBackgroundColor: .systemRed,
                        iconTintColor: .systemRed,
                        titleColor: .systemRed,
                        isLogout: true
                    ) {
                        self.showAlert?("Delete Account")
                    },
                    SettingsOption(title: "Log Out", subtitle: nil, iconName: "rectangle.portrait.and.arrow.right", iconBackgroundColor: .systemRed, iconTintColor: .systemRed, titleColor: .systemRed, isLogout: true) { [weak self] in
                        self?.performLogout()
                    },
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
