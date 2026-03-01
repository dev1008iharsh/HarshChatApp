import Foundation
import Contacts

 
final class ContactService {
    static let shared = ContactService()
    
    func fetchPhoneContacts(completion: @escaping ([ContactModel]) -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else { return }
            
            var contacts = [ContactModel]()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                    let cleanPhone = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                    
                    let model = ContactModel(
                        firstName: contact.givenName,
                        lastName: contact.familyName,
                        phoneNumber: cleanPhone
                    )
                    contacts.append(model)
                }
                completion(contacts)
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }
}
