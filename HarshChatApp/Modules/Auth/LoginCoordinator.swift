//
//  LoginCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//
import UIKit

/// Controls the flow of Authentication module.
/// This class now conforms to LoginCoordinatorProtocol to fix the assignment error.
final class LoginCoordinator {
    
    // MARK: - Properties
    private let window: UIWindow
    private var navigationController: UINavigationController?
    
    // MARK: - Init
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - Flow Control
    func start() {
        // 1. Initialize ViewModel
        let viewModel = LoginViewModel()
        
        // 2. Assign self as the coordinator.
        // This works now because of the extension below.
        viewModel.coordinator = self
        
        // 3. Initialize View Controller with ViewModel
        let loginVC = LoginViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: loginVC)
        
        // 4. Set as root with a smooth transition
        window.rootViewController = navigationController
        
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
        
        window.makeKeyAndVisible()
    }
}

// MARK: - LoginCoordinatorProtocol Implementation
/// This extension tells Swift that LoginCoordinator follows the protocol rules.
extension LoginCoordinator: LoginCoordinatorProtocol {
    
    /// Navigate to Home/Tabbar after successful login
    func didFinishAuth() {
        // TODO: In the future, we will call AppCoordinator or HomeCoordinator here
        print("✅ Auth successful! Transitioning to Home/Tabbar flow...")
        
        // Example: Transition to a dummy Home Screen for testing
        let homeVC = UIViewController()
        homeVC.view.backgroundColor = AppColor.background
        homeVC.title = "Home Screen"
        navigationController?.setViewControllers([homeVC], animated: true)
    }
}
