import Foundation

struct User: Codable {
    let uid: String
    var name: String
    var bio: String
    var email: String?
    var phoneNumber: String
    var profileImageUrl: String?
    var gender: String
    var createdAt: Double

    init(uid: String, phoneNumber: String, name: String = "New User", bio: String = "Hey there! I am using HarshChat 🚀") {
        self.uid = uid
        self.phoneNumber = phoneNumber
        self.name = name
        self.bio = bio
        email = ""
        profileImageUrl = ""
        gender = "Other"
        createdAt = Date().timeIntervalSince1970
    }
}
