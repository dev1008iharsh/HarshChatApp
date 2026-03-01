//
//  AppCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

import UIKit
import FirebaseAuth

/// AppCoordinator is the main entrance of the application's navigation.
/// It decides whether to show the Authentication flow or the Main Chat flow.
final class AppCoordinator {
    
    // MARK: - Properties
    private let window: UIWindow
    private var navigationController: UINavigationController?
    
    // MARK: - Init
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - Flow Control
    
    /// Starts the application flow
    func start() {
        // 2026 Best Practice: Check session on start
        if Auth.auth().currentUser != nil {
            // User is signed in, show Chat List
            showChatList()
        } else {
            // No user is signed in, show Login Screen
            showLogin()
        }
    }
    
    /// Initializes and displays the Login Module (MVVM-C)
    func showLogin() {
        // 1. Initialize ViewModel
        let loginVM = LoginViewModel()
        
        // 2. Initialize ViewController with ViewModel
        let loginVC = LoginViewController(viewModel: loginVM)
        
        // 3. Setup Coordinator reference in ViewModel for navigation
        loginVM.coordinator = self
        
        // 4. Wrap in NavigationController for programmatic push/pop
        navigationController = UINavigationController(rootViewController: loginVC)
        
        // 5. Apply to window
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // Clean appearance: Hide navigation bar for login if needed
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    /// Planned: Show Chat List after successful login
    func showChatList() {
        // 1. Placeholder Chat List VC
        let chatListVC = UIViewController()
        chatListVC.view.backgroundColor = AppColor.background
        chatListVC.title = "Chats"
        
        // 2. Add Logout Button in Navigation Bar
        let logoutButton = UIBarButtonItem(title: "Logout",
                                         style: .plain,
                                         target: self,
                                         action: #selector(handleLogout))
        logoutButton.tintColor = .systemRed
        chatListVC.navigationItem.rightBarButtonItem = logoutButton
        
        // 3. Setup Navigation Controller
        let nav = UINavigationController(rootViewController: chatListVC)
        navigationController = nav // Store reference
        
        // 4. Set as root
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        print("✅ Navigation: User is logged in, showing Chats")
    }

    // MARK: - Logout Logic
    @objc private func handleLogout() {
        do {
            // 1. Firebase Sign Out
            try Auth.auth().signOut()
            
            // 2. Transition back to Login Screen with animation
            print("🚪 User logged out successfully")
            
            UIView.transition(with: window,
                              duration: 0.4,
                              options: .transitionFlipFromRight,
                              animations: {
                self.showLogin()
            }, completion: nil)
            
        } catch let error {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - LoginCoordinator Protocol Implementation
// This allows LoginViewModel to communicate back to the coordinator
extension AppCoordinator: LoginCoordinatorProtocol {
    func didFinishAuth() {
        // Refresh the flow to show Chat List
        showChatList()
    }
}
