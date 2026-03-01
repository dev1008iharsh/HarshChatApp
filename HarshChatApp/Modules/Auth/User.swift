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
    init(uid: String,
         phoneNumber: String,
         name: String = "New User",
         bio: String = "Hey there! I am using HarshChat 🚀",
         profileImageUrl: String? = "") {
        
        self.uid = uid
        self.phoneNumber = phoneNumber
        self.name = name
        self.bio = bio
        self.email = ""
        self.profileImageUrl = profileImageUrl 
        self.gender = "Other"
        self.createdAt = Date().timeIntervalSince1970
    }
}
