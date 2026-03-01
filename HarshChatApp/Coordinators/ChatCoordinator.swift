//
//  ChatCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

final class ChatCoordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let chatListVC = UIViewController() // Replace with ChatListViewController
        chatListVC.view.backgroundColor = AppColor.background
        chatListVC.title = "Chats"
        navigationController.pushViewController(chatListVC, animated: false)
    }
}
