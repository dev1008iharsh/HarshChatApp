//
//  MainTabBarCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

final class MainTabBarCoordinator {
    private let window: UIWindow
    private let tabBarController: UITabBarController
    private var childCoordinators = [AnyObject]()
    weak var parentCoordinator: AppCoordinator?

    init(window: UIWindow) {
        self.window = window
        tabBarController = UITabBarController()
    }

    func start() {
        let chatNav = UINavigationController()
        chatNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "message.fill"), tag: 0)
        let chatCoordinator = ChatCoordinator(navigationController: chatNav)
        chatCoordinator.start()

        let profileNav = UINavigationController()
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle.fill"), tag: 1)
        let profileCoordinator = ProfileCoordinator(navigationController: profileNav)
        profileCoordinator.parentCoordinator = self
        profileCoordinator.start()

        childCoordinators = [chatCoordinator, profileCoordinator]
        tabBarController.viewControllers = [chatNav, profileNav]
        tabBarController.tabBar.tintColor = .systemGreen

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    func logoutUser() {
        parentCoordinator?.childDidFinish(self)
    }
}
