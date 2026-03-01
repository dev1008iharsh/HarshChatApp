import UIKit

final class ConversationListViewController: UIViewController {
    
    private let viewModel = ConversationViewModel()
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColor.primaryTeal
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var filteredConversations = [Conversation]()
    private var isSearching: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        bindViewModel()
        viewModel.fetchConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performFloatingButtonAnimation()
    }

    private func setupUI() {
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        
        tableView.frame = view.bounds
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        view.addSubview(floatingButton)
        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        floatingButton.addTarget(self, action: #selector(didTapNewChat), for: .touchUpInside)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or phone..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }
    }

    private func performFloatingButtonAnimation() {
        floatingButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseInOut) {
            self.floatingButton.transform = .identity
        } completion: { _ in
            self.startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.4
        pulse.fromValue = 1.0
        pulse.toValue = 1.15
        pulse.autoreverses = true
        pulse.repeatCount = 2
        floatingButton.layer.add(pulse, forKey: "pulse")
    }

    @objc private func didTapNewChat() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let newChatVC = NewChatViewController()
        let navVC = UINavigationController(rootViewController: newChatVC)
        
        if #available(iOS 15.0, *) {
            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(navVC, animated: true)
    }
}

extension ConversationListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredConversations.count : viewModel.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.identifier, for: indexPath) as! ConversationCell
        let model = isSearching ? filteredConversations[indexPath.row] : viewModel.conversations[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = isSearching ? filteredConversations[indexPath.row] : viewModel.conversations[indexPath.row]
        let chatVM = ChatViewModel(chatId: conversation.id)
        let chatVC = ChatViewController(viewModel: chatVM)
        chatVC.title = conversation.otherUserName
        navigationController?.pushViewController(chatVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.viewModel.deleteConversation(at: indexPath.row)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension ConversationListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        filteredConversations = viewModel.conversations.filter {
            $0.otherUserName.lowercased().contains(searchText) ||
            ($0.lastMessage.lowercased().contains(searchText))
        }
        tableView.reloadData()
    }
}
