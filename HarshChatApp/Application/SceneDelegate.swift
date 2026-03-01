import FirebaseAuth
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        checkAuthentication()
    }

    func checkAuthentication() {
        if Auth.auth().currentUser != nil {
            showMainTab()
        } else {
            showLogin()
        }
    }

    func showLogin() {
        let viewModel = LoginViewModel()
        viewModel.onSuccess = { [weak self] in
            self?.showMainTab()
        }

        let loginVC = LoginViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)
        setRootViewController(nav, direction: .transitionFlipFromLeft)
    }

    func showMainTab() {
        let tabBar = UITabBarController()

        let chatVC = ConversationListViewController()
        chatVC.view.backgroundColor = .systemBackground
        chatVC.title = "Chats"
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "message.fill"), tag: 0)

        let settingsVM = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 1)

        tabBar.viewControllers = [chatNav, settingsNav]
        tabBar.tabBar.tintColor = AppColor.primaryTeal
        tabBar.tabBar.backgroundColor = .systemBackground

        setRootViewController(tabBar, direction: .transitionFlipFromRight)
    }

    private func setRootViewController(_ vc: UIViewController, direction: UIView.AnimationOptions) {
        guard let window = window else { return }
        window.rootViewController = vc
        window.makeKeyAndVisible()

        UIView.transition(with: window, duration: 0.5, options: direction, animations: nil)
    }
}
