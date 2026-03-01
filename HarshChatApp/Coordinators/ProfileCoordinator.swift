//
//  ProfileCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import FirebaseAuth
import UIKit

final class ProfileCoordinator {
    var navigationController: UINavigationController
    weak var parentCoordinator: MainTabBarCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let profileVC = UIViewController()
        profileVC.view.backgroundColor = AppColor.background
        profileVC.title = "Profile"

        let logoutBtn = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTapped))
        profileVC.navigationItem.rightBarButtonItem = logoutBtn

        navigationController.pushViewController(profileVC, animated: false)
    }

    @objc private func logoutTapped() {
        parentCoordinator?.logoutUser()
    }
}
