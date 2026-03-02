//
//  SettingsViewModel.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

// MARK: - SettingsViewModel

/// Manages the logic for the user settings screen, including profile data fetching and session management.
final class SettingsViewModel {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var currentUser: User?
    var sections = [SettingsSection]()

    // Output closures to communicate events back to the ViewController
    var onDataUpdate: (() -> Void)? // Triggers when profile data changes
    var onError: ((String) -> Void)? // Triggers when a Firebase error occurs
    var onLogout: (() -> Void)? // Triggers after successful logout
    var onNavigateToEdit: ((User) -> Void)? // Triggers to navigate to Edit Profile
    var showAlert: ((String) -> Void)? // Triggers for generic info alerts

    // MARK: - Data Fetching

    /// Sets up a real-time listener to fetch current user data from Firestore.
    /// This ensures the settings UI stays in sync if the user updates their profile elsewhere.
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("DEBUG: No user logged in")
            return
        }

        // Clean up existing listener before creating a new one
        listener?.remove()

        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("DEBUG: Firestore listener error: \(error.localizedDescription)")
                self.onError?(error.localizedDescription)
                return
            }

            guard let data = snapshot?.data() else { return }

            // Map the dictionary data to our User model
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

            // Rebuild the table sections with the new user data
            print("DEBUG: User data updated for: \(user.name)")
            self.setupSections()
            self.onDataUpdate?()
        }
    }

    // MARK: - Section Building

    /// Configures the layout and options available in the settings table view.
    private func setupSections() {
        sections.removeAll()

        // 1. Profile Section: Tapping this triggers navigation to EditProfile
        let profileOption = SettingsOption(
            title: currentUser?.name ?? "User",
            subtitle: currentUser?.bio,
            iconName: "person.fill",
            iconBackgroundColor: .systemGray5,
            iconTintColor: AppColor.primaryColor,
            titleColor: AppColor.primaryText,
            isLogout: false
        ) { [weak self] in
            if let user = self?.currentUser {
                self?.onNavigateToEdit?(user)
            }
        }
        sections.append(SettingsSection(title: "Profile", options: [profileOption]))

        // 2. App Settings Section: Modern list of functional app settings
        sections.append(
            SettingsSection(
                title: "App Settings",
                options: [
                    SettingsOption(title: "Account", subtitle: "Privacy, security", iconName: "key.fill", iconBackgroundColor: .systemBlue, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Account Settings") },
                    SettingsOption(title: "Chats", subtitle: "Theme, wallpapers", iconName: "message.fill", iconBackgroundColor: AppColor.primaryColor, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Chat Settings") },
                    SettingsOption(title: "Notifications", subtitle: "Tones", iconName: "bell.badge.fill", iconBackgroundColor: .systemRed, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Notifications") },
                    SettingsOption(title: "Storage", subtitle: "Network usage", iconName: "chart.pie.fill", iconBackgroundColor: .systemGreen, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Storage and Data") },
                ]
            )
        )

        // 3. Help & Social Section
        sections.append(SettingsSection(title: "Help", options: [
            SettingsOption(title: "Help Center", subtitle: "FAQ, contact us", iconName: "questionmark.circle.fill", iconBackgroundColor: .systemGray, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Help Center") },
            SettingsOption(title: "Invite a Friend", subtitle: nil, iconName: "person.2.fill", iconBackgroundColor: .systemPink, iconTintColor: AppColor.primaryText, titleColor: AppColor.primaryText, isLogout: false) { self.showAlert?("Invite a Friend") },
        ]))

        // 4. Session Actions Section
        sections.append(
            SettingsSection(
                title: "Actions",
                options: [
                    SettingsOption(title: "Log Out", subtitle: nil, iconName: "rectangle.portrait.and.arrow.right", iconBackgroundColor: .systemRed, iconTintColor: .systemRed, titleColor: .systemRed, isLogout: true) { [weak self] in
                        self?.performLogout()
                    },
                ]
            )
        )
    }

    // MARK: - Actions

    /// Signs the user out of Firebase Authentication and clears the local session.
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            print("DEBUG: User logged out successfully")
            onLogout?()
        } catch {
            print("DEBUG: Logout failed: \(error.localizedDescription)")
            onError?(error.localizedDescription)
        }
    }

    deinit {
        // Essential for memory safety: removes the Firestore listener when ViewModel is destroyed
        listener?.remove()
    }
}
