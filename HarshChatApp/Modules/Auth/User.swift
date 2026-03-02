//
//  User.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import Foundation

// MARK: - User Model

/// Data structure representing a chat user, conforming to Codable for easy Firestore mapping.
struct User: Codable {
    // MARK: - Properties

    let uid: String
    var name: String
    var bio: String
    var email: String?
    var phoneNumber: String
    var profileImageUrl: String?
    var gender: String
    var createdAt: Double

    // MARK: - Initializer

    /// Default initializer to create a new user profile with initial values.
    init(uid: String,
         phoneNumber: String,
         name: String = "New User",
         bio: String = "Hey there! I am using HarshChat 🚀",
         profileImageUrl: String? = "") {
        self.uid = uid
        self.phoneNumber = phoneNumber
        self.name = name
        self.bio = bio
        email = ""
        self.profileImageUrl = profileImageUrl
        gender = "Other"
        createdAt = Date().timeIntervalSince1970

        print("👤 [Debug] Model: User object initialized for UID: \(uid)")
    }
}
