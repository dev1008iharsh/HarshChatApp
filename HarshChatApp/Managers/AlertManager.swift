//
//  AlertManager.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

// MARK: - AlertManager Structure
struct AlertManager {
    enum LoginError {
        case invalidPhone
        case invalidOTP
        case custom(String)
        
        var title: String { "Error" }
        var message: String {
            switch self {
            case .invalidPhone: return "Please enter a valid 10-digit phone number."
            case .invalidOTP: return "Please enter the 6-digit OTP sent to your phone."
            case .custom(let msg): return msg
            }
        }
    }
    
    static func showAlert(on vc: UIViewController, type: LoginError) {
        let alert = UIAlertController(title: type.title, message: type.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
    
    // Overload for general messages
    static func showAlert(on vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}
