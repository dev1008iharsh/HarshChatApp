//
//  AppDelegate.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - App Lifecycle

    /// Entry point of the application where Firebase and other initial services are configured.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // MARK: Firebase Configuration

        // Initializing Firebase at the start of the app
        FirebaseApp.configure()
        print("🔥 [Debug] Firebase: Configured successfully.")

        return true
    }

    // MARK: - UISceneSession Lifecycle

    /// Called when a new scene session is being created.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("📱 [Debug] Scene: Connecting new scene session.")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user discards a scene session.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("🗑️ [Debug] Scene: Discarded scene sessions.")
    }
}
