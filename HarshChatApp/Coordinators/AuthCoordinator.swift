//
//  AuthCoordinator.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

final class AuthCoordinator: LoginCoordinatorProtocol {
    private let window: UIWindow
    private var navigationController: UINavigationController?
    weak var parentCoordinator: AppCoordinator?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let viewModel = LoginViewModel()
        viewModel.coordinator = self
        let loginVC = LoginViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: loginVC)
        navigationController?.setNavigationBarHidden(true, animated: false)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func didFinishAuth() {
        parentCoordinator?.childDidFinish(self)
    }
}
