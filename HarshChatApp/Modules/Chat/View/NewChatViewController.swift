//
//  NewChatViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import MessageUI
import UIKit

// MARK: - NewChatViewController

/// This controller allows users to pick a contact from their phone book
/// or manually search for a 10-digit phone number to start a new chat.
final class NewChatViewController: UIViewController {
    // MARK: - Properties

    // ViewModel handles contact fetching and Firebase search logic.
    private let viewModel = NewChatViewModel()

    // TableView to display the list of device contacts.
    private let tableView = UITableView()

    /// Custom Search Field with a fixed "+91" prefix for Indian numbers.
    private let searchField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 10-digit number to start chat"
        tf.keyboardType = .phonePad
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12

        // Creating a custom left view for the country code.
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        label.text = "  +91 "
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColor.primaryText
        tf.leftView = label
        tf.leftViewMode = .always

        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bindViewModel()

        // Initial load of contacts from the device.
        viewModel.loadAndCheckContacts()
    }

    // MARK: - UI Setup

    /// Sets up the view hierarchy and Auto Layout constraints.
    private func setupUI() {
        title = "Select Contact"
        view.backgroundColor = AppColor.background

        view.addSubview(searchField)
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Constraints to position search bar at top and table below it.
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            searchField.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Observe text changes in the search field.
        searchField.addTarget(self, action: #selector(searchDidChanged), for: .editingChanged)
    }

    /// Configures the navigation bar buttons and theme.
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationController?.navigationBar.tintColor = AppColor.primaryColor
    }

    /// Binds ViewModel callbacks to the UI.
    private func bindViewModel() {
        // Reload table whenever contact list is updated.
        viewModel.onDataLoaded = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }
    }

    // MARK: - Actions

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    /// Triggered whenever the user types in the search field.
    @objc private func searchDidChanged(_ textField: UITextField) {
        guard let text = textField.text, text.count == 10 else {
            // If less than 10 digits, just filter the local contact list.
            viewModel.filterContacts(with: textField.text ?? "")
            return
        }

        // If exactly 10 digits are entered, search for this user on Firebase.
        viewModel.searchUser(with: text) { [weak self] registeredUser in
            if let user = registeredUser {
                self?.startChat(with: user)
            } else {
                // If user doesn't exist on Firebase, show invite option.
                self?.showInviteAlert(number: "+91\(text)")
            }
        }
    }

    /// Navigates to the individual chat screen.
    private func startChat(with user: ChatUser) {
        let chatId = viewModel.generateChatId(with: user.senderId)
        let chatVM = ChatViewModel(chatId: chatId, otherUser: user)
        let chatVC = ChatViewController(viewModel: chatVM)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    /// Shows an alert to invite a non-registered user via SMS.
    func showInviteAlert(number: String) {
        let alert = UIAlertController(
            title: "User Not Found",
            message: "\(number) is not on HarshChat yet. Invite them?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Invite via SMS", style: .default, handler: { [weak self] _ in
            self?.sendSMS(number: number)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    /// Opens the native SMS composer.
    func sendSMS(number: String) {
        // Check if the device is capable of sending text messages.
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.body = "I am inviting you to this wonderful chat app called HarshChatApp! Download it here: https://dev1008iharsh.github.io/"
            vc.recipients = [number]
            vc.messageComposeDelegate = self
            present(vc, animated: true)
        } else {
            AlertManager
                .showAlert(
                    title: "Error",
                    message: "SMS service not available.",
                    vc: self
                )
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension NewChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredContacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ContactCell")
        let contact = viewModel.filteredContacts[indexPath.row]

        // Displaying full name and formatted phone number.
        cell.textLabel?.text = "\(contact.firstName) \(contact.lastName)"
        cell.detailTextLabel?.text = contact.phoneNumber
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = viewModel.filteredContacts[indexPath.row]

        // Remove non-numeric characters before searching on Firebase.
        let cleanNumber = contact.phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // Logic to check if contact is a registered user.
        viewModel.searchUser(with: cleanNumber) { [weak self] user in
            if let registeredUser = user {
                self?.startChat(with: registeredUser)
            } else {
                self?.showInviteAlert(number: contact.phoneNumber)
            }
        }
    }
}

// MARK: - MFMessageCompose Delegate

extension NewChatViewController: MFMessageComposeViewControllerDelegate {
    /// Dismisses the SMS composer after the user sends or cancels the message.
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}
