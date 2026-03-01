//
//  AppCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import FirebaseAuth
import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private var childCoordinator: AnyObject?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        if Auth.auth().currentUser != nil {
            showMainFlow()
        } else {
            showAuthFlow()
        }
    }

    private func showAuthFlow() {
        let authCoord = AuthCoordinator(window: window)
        authCoord.parentCoordinator = self
        childCoordinator = authCoord

        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            authCoord.start()
        })
    }

    private func showMainFlow() {
        let tabCoord = MainTabBarCoordinator(window: window)
        tabCoord.parentCoordinator = self
        childCoordinator = tabCoord

        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: {
            tabCoord.start()
        })
    }

    func childDidFinish(_ child: AnyObject) {
        if child is AuthCoordinator {
            showMainFlow()
        } else if child is MainTabBarCoordinator {
            try? Auth.auth().signOut()
            showAuthFlow()
        }
    }
}
