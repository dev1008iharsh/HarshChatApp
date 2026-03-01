import UIKit
import MessageUI

final class NewChatViewController: UIViewController {
    
    private let viewModel = NewChatViewModel()
    private let tableView = UITableView()
    
    private let searchField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 10-digit number"
        tf.keyboardType = .phonePad
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        label.text = "  +91 "
        label.font = AppFont.bold.set(size: 16)
        label.textColor = AppColor.primaryTeal
        tf.leftView = label
        tf.leftViewMode = .always
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bindViewModel()
        viewModel.loadAndCheckContacts()
    }

    private func setupUI() {
        title = "Select Contact"
        view.backgroundColor = .systemBackground
        
        view.addSubview(searchField)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            searchField.heightAnchor.constraint(equalToConstant: 50),
            
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        searchField.addTarget(self, action: #selector(searchDidChanged), for: .editingChanged)
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationController?.navigationBar.tintColor = AppColor.primaryTeal
    }

    private func bindViewModel() {
        viewModel.onDataLoaded = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func searchDidChanged(_ textField: UITextField) {
        guard let text = textField.text, text.count == 10 else { return }
        
        viewModel.searchUser(with: text) { [weak self] user in
            if let registeredUser = user {
                self?.startChat(with: registeredUser)
            } else {
                self?.showInviteAlert(number: "+91\(text)")
            }
        }
    }

    private func startChat(with user: User) {
        let chatId = viewModel.generateChatId(with: user.uid)
        let chatVM = ChatViewModel(chatId: chatId)
        let chatVC = ChatViewController(viewModel: chatVM)
        chatVC.title = user.name
        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func showInviteAlert(number: String) {
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

    private func sendSMS(number: String) {
        // ✅ સિમ્યુલેટર પર આ કામ નહીં કરે, ફિઝિકલ આઇફોન જોઈએ
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.body = "I am inviting you to this wonderful chat app! Download it here: https://dev1008iharsh.github.io/"
            vc.recipients = [number]
            vc.messageComposeDelegate = self
            self.present(vc, animated: true, completion: nil)
        } else {
            // જો સિમ્યુલેટર હોય તો આ એલર્ટ આવશે
            let errorAlert = UIAlertController(title: "Error", message: "SMS service is not available on this device (Simulators don't support SMS).", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(errorAlert, animated: true)
        }
    }
}

extension NewChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ContactCell")
        let contact = viewModel.filteredContacts[indexPath.row]
        cell.textLabel?.text = "\(contact.firstName) \(contact.lastName)"
        cell.detailTextLabel?.text = contact.phoneNumber
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = viewModel.filteredContacts[indexPath.row]
        self.showInviteAlert(number: contact.phoneNumber)
    }
}

extension NewChatViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
