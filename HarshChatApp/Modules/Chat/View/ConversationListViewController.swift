//
//  ConversationListViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import UIKit

// MARK: - ConversationListViewController

/// The main screen of the app that displays a list of all active chat conversations.
final class ConversationListViewController: UIViewController {
    // MARK: - Properties

    // ViewModel responsible for fetching and managing the conversation data from Firestore.
    private let viewModel = ConversationViewModel()

    // ✅ Pulse Button (Floating Action Button)
    /// A floating '+' button to initiate a new chat.
    private let floatingButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.backgroundColor = AppColor.primaryColor
        btn.tintColor = .white
        btn.layer.cornerRadius = 30 // Makes the button circular (60/2).

        // Shadow properties for a floating depth effect.
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 5

        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // TableView to display the list of conversations.
    private let tableView: UITableView = {
        let tv = UITableView()
        // Registering the custom cell we created earlier.
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.identifier)
        tv.backgroundColor = AppColor.background
        tv.separatorStyle = .singleLine
        // tv.separatorColor = .systemGray4
        // Adjusting separator inset to align with the text, not the profile image.
        // tv.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
        tv.tableFooterView = UIView() // Removes empty separator lines at the bottom.
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        startPulseAnimation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        // Refresh conversations every time the screen appears.
        viewModel.fetchConversations()
    }

    // MARK: - UI Setup

    /// Configures the view hierarchy and layout constraints.
    private func setupUI() {
        title = "Chats"
        view.backgroundColor = AppColor.background
        view.addSubview(tableView)
        view.addSubview(floatingButton)

        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            // TableView occupies the full screen.
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Floating Action Button constraints (Bottom Right).
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])

        floatingButton.addTarget(self, action: #selector(didTapNewChat), for: .touchUpInside)
    }

    /// Binds the ViewModel's update closure to reload the TableView.
    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Animations

    /// Creates a continuous pulsing effect on the floating button to grab user attention.
    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.2
        pulse.fromValue = 1.0
        pulse.toValue = 1.1
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true // Scales back to original size.
        pulse.repeatCount = .infinity // Keeps animating forever.
        floatingButton.layer.add(pulse, forKey: "pulse")
    }

    // MARK: - Actions

    @objc private func didTapNewChat() {
        guard NetworkChecker.isConnected else {
            AlertManager.showAlert(title: "No Internet", message: "Please check your connection and try again.", vc: self)
            return
        }

        // Haptic Feedback: Provides a physical 'click' feel to the user.
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let vc = NewChatViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

// MARK: - TableView Extensions

extension ConversationListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.identifier, for: indexPath) as? ConversationCell else {
            return UITableViewCell()
        }
        // Configuring the cell with conversation data.
        cell.configure(with: viewModel.conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90 // Sufficient height for profile image and two lines of text.
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let conversation = viewModel.conversations[indexPath.row]

        // Mapping conversation data to ChatUser to open the chat screen.
        let user = ChatUser(
            senderId: conversation.otherUserId,
            displayName: conversation.otherUserName,
            phoneNumber: conversation.otherUserPhone,
            profileImageUrl: conversation.profileImageUrl
        )

        let chatVM = ChatViewModel(chatId: conversation.id, otherUser: user)
        let chatVC = ChatViewController(viewModel: chatVM)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    // MARK: - Swipe Actions (Delete & Archive)

    // MARK: - Swipe Actions (Delete & Archive)

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Action to trigger the delete options
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in

            // Action Sheet for choosing Delete type
            let actionSheet = UIAlertController(title: "Delete Chat", message: "What would you like to do?", preferredStyle: .actionSheet)

            // Option 1: Delete only for me (Like WhatsApp Clear Chat)
            actionSheet.addAction(UIAlertAction(title: "Delete for Me", style: .default, handler: { _ in
                self?.viewModel.deleteChatForMe(at: indexPath.row)
                completion(true)
            }))

            // Option 2: Delete for everyone (Wipe everything)
            actionSheet.addAction(UIAlertAction(title: "Delete for Everyone", style: .destructive, handler: { _ in
                self?.viewModel.deleteChatForEveryone(at: indexPath.row)
                completion(true)
            }))

            // Cancel
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                completion(false)
            }))

            // iPad Support
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = tableView
                popoverController.sourceRect = tableView.rectForRow(at: indexPath)
            }

            self?.present(actionSheet, animated: true)
        }

        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed

        // Disable full swipe to prevent accidental deletion without choosing an option
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false

        return configuration
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Action to archive a conversation (Placeholder logic).
        let archiveAction = UIContextualAction(style: .normal, title: nil) { _, _, completion in
            print("Archive tapped for row: \(indexPath.row)")
            completion(true)
        }
        archiveAction.image = UIImage(systemName: "archivebox.fill")
        archiveAction.backgroundColor = AppColor.primaryColor

        return UISwipeActionsConfiguration(actions: [archiveAction])
    }
}
