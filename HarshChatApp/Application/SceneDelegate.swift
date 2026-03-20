//
//  SceneDelegate.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//  💼 LinkedIn → https://www.linkedin.com/in/dev1008iharsh/
//  📦 GitHub Repositories → https://github.com/dev1008iharsh?tab=repositories
//

//
//  SceneDelegate.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

// MARK: - SceneDelegate

/// Manages the app's window lifecycle. UI routing is handled by AppRouter.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        print("🚀 [Debug] SceneDelegate: Window Scene connected.")

        // Create the main window
        let mainWindow = UIWindow(windowScene: windowScene)
        window = mainWindow

        // Hand over the navigation control to the AppRouter
        AppRouter.shared.start(in: mainWindow)
    }

    // Default lifecycle methods...
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
