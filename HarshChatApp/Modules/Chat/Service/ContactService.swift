//
//  ContactService.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import Contacts
import Foundation

// MARK: - ContactModel

/// A simple data structure to represent a contact's basic information.
struct ContactModel {
    let firstName: String
    let lastName: String
    let phoneNumber: String

    /// Computed property to get the full name easily.
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - ContactService

/// This Service is responsible for requesting permission and fetching contacts from the device.
final class ContactService {
    // Singleton instance to access this service globally.
    static let shared = ContactService()

    // Private initializer to prevent multiple instances (Singleton Pattern).
    private init() {}

    /// Fetches all contacts from the phone's address book that have phone numbers.
    /// - Parameter completion: Returns an array of formatted ContactModel objects.
    func fetchPhoneContacts(completion: @escaping ([ContactModel]) -> Void) {
        let store = CNContactStore()

        // 1. Request access from the user to read contacts.
        store.requestAccess(for: .contacts) { granted, error in

            // If access is denied, return an empty array on the main thread.
            guard granted else {
                print("⚠️ [Debug] Access Denied: Please enable contacts in Settings.")
                DispatchQueue.main.async { completion([]) }
                return
            }

            // 2. Perform fetching in a background thread to keep UI responsive.
            DispatchQueue.global(qos: .userInitiated).async {
                var contacts = [ContactModel]()

                // Keys define exactly which data we want to fetch (Performance optimization).
                let keys = [CNContactGivenNameKey,
                            CNContactFamilyNameKey,
                            CNContactPhoneNumbersKey] as [CNKeyDescriptor]

                let request = CNContactFetchRequest(keysToFetch: keys)

                do {
                    // 3. Iterate through all contacts in the phone.
                    try store.enumerateContacts(with: request) { contact, _ in

                        // Extract the first phone number if it exists.
                        guard let phoneValue = contact.phoneNumbers.first?.value.stringValue else { return }

                        // ✅ Formatting: Remove brackets, spaces, and dashes using Regex.
                        // This ensures " (999) 000-1111" becomes "+919990001111" or "9990001111".
                        let cleanPhone = phoneValue.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

                        let model = ContactModel(
                            firstName: contact.givenName,
                            lastName: contact.familyName,
                            phoneNumber: cleanPhone
                        )
                        contacts.append(model)
                    }

                    // 4. Send the result back to the Main Thread for UI updates.
                    print("✅ [Debug] Fetched \(contacts.count) contacts successfully.")
                    DispatchQueue.main.async {
                        completion(contacts)
                    }

                } catch {
                    print("❌ [Debug] Error fetching contacts: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion([]) }
                }
            }
        }
    }
}
