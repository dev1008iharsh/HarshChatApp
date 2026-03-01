import Foundation
import Contacts

final class ContactService {
    static let shared = ContactService()
    private init() {}
    
    func fetchPhoneContacts(completion: @escaping ([ContactModel]) -> Void) {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                completion([])
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                var contacts = [ContactModel]()
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                
                do {
                    try store.enumerateContacts(with: request) { contact, _ in
                        let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                        // ✅ Formatting: Remove brackets, spaces, and dashes
                        let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                        
                        let model = ContactModel(
                            firstName: contact.givenName,
                            lastName: contact.familyName,
                            phoneNumber: cleanPhone
                        )
                        contacts.append(model)
                    }
                    
                    DispatchQueue.main.async {
                        completion(contacts)
                    }
                } catch {
                    print("❌ Error fetching contacts: \(error)")
                    completion([])
                }
            }
        }
    }
}

struct ContactModel {
    let firstName: String
    let lastName: String
    let phoneNumber: String
}
