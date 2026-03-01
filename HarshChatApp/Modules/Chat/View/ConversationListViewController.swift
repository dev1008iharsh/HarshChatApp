import UIKit

final class ConversationListViewController: UIViewController {

    private let viewModel = ConversationViewModel()
    
    // ✅ Pulse Button (Floating Action Button)
    private let floatingButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.backgroundColor = AppColor.primaryColor
        btn.tintColor = .white
        btn.layer.cornerRadius = 30
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.identifier)
        tv.backgroundColor = AppColor.background
        tv.separatorColor = .systemGray4
        tv.separatorInset = UIEdgeInsets(top: 0, left: 88, bottom: 0, right: 0)
        tv.tableFooterView = UIView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar() // ✅ Navigation setup should be first or handled carefully
        setupUI()
        bindViewModel()
        startPulseAnimation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ✅ Ensure large titles are enabled every time the view appears
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        viewModel.fetchConversations()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.background
        view.addSubview(tableView)
        view.addSubview(floatingButton)
        
        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            // ✅ Fix: Use safeAreaLayoutGuide for top if titles are being hidden
            // અથવા view.topAnchor વાપરો પણ ખાતરી કરો કે navigationBar transparent નથી
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        floatingButton.addTarget(self, action: #selector(didTapNewChat), for: .touchUpInside)
    }

    private func setupNavigationBar() {
        title = "HarshChat"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.background
        
        // Title Text Attributes
        appearance.largeTitleTextAttributes = [
            .font: AppFont.bold.set(size: 34),
            .foregroundColor: AppColor.primaryText
        ]
        
        appearance.titleTextAttributes = [
            .font: AppFont.bold.set(size: 17),
            .foregroundColor: AppColor.primaryText
        ]
        
        // ✅ Apply to all states
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.tintColor = AppColor.primaryColor
    }

    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.2
        pulse.fromValue = 1.0
        pulse.toValue = 1.1
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        floatingButton.layer.add(pulse, forKey: "pulse")
    }

    @objc private func didTapNewChat() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let vc = NewChatViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

// MARK: - TableView & Swipe Actions
extension ConversationListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.identifier, for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = viewModel.conversations[indexPath.row]
        let user = ChatUser(senderId: conversation.otherUserId, displayName: conversation.otherUserName, phoneNumber: conversation.otherUserPhone, profileImageUrl: conversation.profileImageUrl)
        let chatVM = ChatViewModel(chatId: conversation.id, otherUser: user)
        let chatVC = ChatViewController(viewModel: chatVM)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
         
            let alert = UIAlertController(title: "Delete Chat?",
                                          message: "Are you sure you want to delete this conversation and all its messages? This cannot be undone.",
                                          preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
               
                self?.viewModel.deleteConversation(at: indexPath.row)
                completion(true)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                completion(false)
            }))
           
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = tableView
                popoverController.sourceRect = tableView.rectForRow(at: indexPath)
            }
            
            self?.present(alert, animated: true)
        }
        
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true 
        return configuration
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let archiveAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
            print("Archive tapped")
            completion(true)
        }
        archiveAction.image = UIImage(systemName: "archivebox.fill")
        archiveAction.backgroundColor = AppColor.primaryColor
        return UISwipeActionsConfiguration(actions: [archiveAction])
    }
}
