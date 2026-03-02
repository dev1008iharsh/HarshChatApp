//
//  SceneDelegate.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import FirebaseAuth
import UIKit

// MARK: - SceneDelegate

/// Manages the app's window and root navigation logic based on Auth status.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?

    // MARK: - Scene Lifecycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        print("🚀 [Debug] SceneDelegate: Window Scene connecting...")

        window = UIWindow(windowScene: windowScene)
        checkAuthentication()
    }

    // MARK: - Authentication Flow

    /// Logic to decide whether to show the Login flow or Main App flow.
    func checkAuthentication() {
        if Auth.auth().currentUser != nil {
            print("✅ [Debug] Auth: User detected. Route to MainTab.")
            showMainTab()
        } else {
            print("🔑 [Debug] Auth: No user found. Route to Login.")
            showLogin()
        }
    }

    // MARK: - Navigation Transitions

    /// Initializes and displays the LoginViewController.
    func showLogin() {
        let viewModel = LoginViewModel()
        viewModel.onSuccess = { [weak self] in
            print("🎯 [Debug] Flow: Login success callback received.")
            self?.showMainTab()
        }

        let loginVC = LoginViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)

        setRootViewController(nav, direction: .transitionFlipFromLeft)
    }

    /// Initializes and displays the main TabBar of the application.
    func showMainTab() {
        let tabBar = UITabBarController()
        tabBar.delegate = self
        // 1. Conversation / Chat List
        let chatVC = ConversationListViewController()
        chatVC.title = "Chats"
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.navigationBar.tintColor = AppColor.primaryColor
        chatNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        chatNav.navigationBar.prefersLargeTitles = true

        // 2. Settings
        let settingsVM = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        settingsVC.title = "Settings"
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.navigationBar.tintColor = AppColor.primaryColor
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        settingsNav.navigationBar.prefersLargeTitles = true

        // MARK: UI Appearance Configuration

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.tabBar.standardAppearance = appearance
            tabBar.tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.viewControllers = [chatNav, settingsNav]
        tabBar.tabBar.tintColor = AppColor.primaryColor

        print("📱 [Debug] Navigation: Setting Main TabBar as Root.")
        setRootViewController(tabBar, direction: .transitionCrossDissolve)
    }

    // MARK: - Helper Methods

    /// Updates the rootViewController with a smooth animation transition.
    private func setRootViewController(_ vc: UIViewController, direction: UIView.AnimationOptions) {
        guard let window = window else { return }
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Apply smooth transition animation
        UIView.transition(with: window, duration: 0.5, options: direction, animations: nil)
    }
}

extension SceneDelegate: UITabBarControllerDelegate {
    /// MAJOR EVENT: Trigger Haptic Feedback when a tab is selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare() // Warm up the engine
        generator.selectionChanged() // Trigger the haptic
    }
}
