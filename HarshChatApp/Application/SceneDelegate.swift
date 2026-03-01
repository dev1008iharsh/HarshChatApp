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

        // 1. Conversation / Chat List
        let chatVC = ConversationListViewController()
        chatVC.title = "Chats"
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "bubble.left.and.bubble.right"), selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
        chatNav.navigationBar.prefersLargeTitles = true // ✅ Makes it look professional

        // 2. Settings
        let settingsVM = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        settingsVC.title = "Settings"
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        settingsNav.navigationBar.prefersLargeTitles = true

        // ✅ TabBar Appearance Fix for iOS 15+
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.tabBar.standardAppearance = appearance
            tabBar.tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.viewControllers = [chatNav, settingsNav]
        tabBar.tabBar.tintColor = AppColor.primaryColor
        
        // ✅ Smooth Transition
        setRootViewController(tabBar, direction: .transitionCrossDissolve)
    }

    private func setRootViewController(_ vc: UIViewController, direction: UIView.AnimationOptions) {
        guard let window = window else { return }
        window.rootViewController = vc
        window.makeKeyAndVisible()

        UIView.transition(with: window, duration: 0.5, options: direction, animations: nil)
    }
}
