//
//  AppRouter.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - AppRouter

/// A singleton class responsible for managing the root view controller and app navigation flow.
/// Implements the Coordinator/Router pattern to keep SceneDelegate clean.
@MainActor
final class AppRouter: NSObject { // ✅ FIX: Must inherit from NSObject to act as a UITabBarControllerDelegate
    // Singleton instance for global access
    static let shared = AppRouter()

    // The main window of the application
    private var window: UIWindow?

    // ✅ FIX: Override init since we are inheriting from NSObject
    override private init() {
        super.init()
    }

    // MARK: - App Start

    /// Called from SceneDelegate to begin the routing process.
    func start(in window: UIWindow) {
        _ = NetworkChecker.shared
        self.window = window
        self.window?.makeKeyAndVisible()
        checkAuthentication()
    }

    // MARK: - Authentication Flow

    /// Verifies Firebase Auth and Firestore data integrity to route the user correctly.
    private func checkAuthentication() {
        // 1. Check Auth State
        guard let currentUser = Auth.auth().currentUser else {
            print("🔑 [Debug] AppRouter: No user in Auth. Routing to Login.")
            showLogin()
            return
        }

        let uid = currentUser.uid
        print("⏳ [Debug] AppRouter: User found in Auth (\(uid)). Verifying Firestore...")

        // Show a temporary loading screen during network request
        showTemporaryLoadingScreen()

        // 2. Verify Data in Firestore
        Task {
            do {
                let db = Firestore.firestore()
                let document = try await db.collection("users").document(uid).getDocument()

                if document.exists {
                    print("✅ [Debug] AppRouter: User data verified. Routing to MainTab.")
                    self.showMainTab()
                } else {
                    print("⚠️ [Debug] AppRouter: Data missing in Firestore. Forcing logout.")
                    self.forceLogout()
                }
            } catch {
                print("❌ [Debug] AppRouter: Firestore error. Forcing logout. Error: \(error.localizedDescription)")
                self.forceLogout()
            }
        }
    }

    /// Safely signs out the user and redirects to Login.
    func forceLogout() {
        do {
            try Auth.auth().signOut()
            showLogin()
        } catch {
            print("❌ [Debug] AppRouter: Error signing out: \(error.localizedDescription)")
            showLogin()
        }
    }

    // MARK: - Routing Methods

    /// Displays a generic loading spinner as the root view.

    // MARK: - Routing Methods

    /// Displays a generic loading screen with app logo, spinner, and status message.
    private func showTemporaryLoadingScreen() {
        let loadingVC = UIViewController()
        loadingVC.view.backgroundColor = AppColor.background

        // 1. App Logo ImageView
        let logoImageView = UIImageView(image: UIImage(named: "RoundAppIconLaunch"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        // Setting a fixed size for the logo to keep it consistent
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 150),
            logoImageView.heightAnchor.constraint(equalToConstant: 150),
        ])

        // 2. Activity Indicator (Spinner)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppColor.primaryColor
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        // 3. Status Message Label
        let statusLabel = UILabel()
        statusLabel.text = "Authenticating user...\nChecking account status"
        statusLabel.textColor = AppColor.secondaryText
        statusLabel.font = AppFont.regular.set(size: 18)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0 // Allows text to wrap to multiple lines if needed
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // 4. StackView to hold Logo, Spinner, and Label vertically
        let stackView = UIStackView(arrangedSubviews: [logoImageView, spinner, statusLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20 // Consistent space between all elements
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add StackView to the main view
        loadingVC.view.addSubview(stackView)

        // Center the StackView perfectly in the middle of the screen
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: loadingVC.view.centerYAnchor),

            // Adding padding on left and right so text doesn't touch screen edges
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: loadingVC.view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: loadingVC.view.trailingAnchor, constant: -30),
        ])

        // Smooth transition to the loading screen
        setRootViewController(loadingVC, direction: .transitionCrossDissolve)
    }

    /// Sets up and presents the Login Screen.
    func showLogin() {
        let viewModel = LoginViewModel()
        viewModel.onSuccess = { [weak self] in
            print("🎯 [Debug] AppRouter: Login success callback received.")
            self?.showMainTab()
        }

        let loginVC = LoginViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)

        setRootViewController(nav, direction: .transitionFlipFromLeft)
    }

    /// Sets up and presents the Main TabBar Screen.
    func showMainTab() {
        let tabBar = UITabBarController()
        tabBar.delegate = self // ✅ FIX: AppRouter is now the delegate

        // Setup Chat Tab
        let chatVC = ConversationListViewController()
        chatVC.title = "Chats"
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.navigationBar.tintColor = AppColor.primaryColor
        chatNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        chatNav.navigationBar.prefersLargeTitles = true

        // Setup Settings Tab
        let settingsVM = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        settingsVC.title = "Settings"
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.navigationBar.tintColor = AppColor.primaryColor
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        settingsNav.navigationBar.prefersLargeTitles = true

        // Apply modern TabBar appearance
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.tabBar.standardAppearance = appearance
            tabBar.tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.viewControllers = [chatNav, settingsNav]
        tabBar.tabBar.tintColor = AppColor.primaryColor

        print("📱 [Debug] AppRouter: Setting Main TabBar as Root.")
        setRootViewController(tabBar, direction: .transitionFlipFromRight)
    }

    // MARK: - Root Transition

    /// Smoothly animates the transition between root view controllers.
    private func setRootViewController(_ vc: UIViewController, direction: UIView.AnimationOptions) {
        guard let window = window else { return }
        window.rootViewController = vc

        // Apply smooth transition animation
        UIView.transition(with: window, duration: 0.4, options: direction, animations: nil)
    }
}

// MARK: - UITabBarControllerDelegate

extension AppRouter: UITabBarControllerDelegate {
    /// MAJOR EVENT: Trigger Haptic Feedback when a tab is selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare() // Warm up the engine
        generator.selectionChanged() // Trigger the haptic
    }
}
