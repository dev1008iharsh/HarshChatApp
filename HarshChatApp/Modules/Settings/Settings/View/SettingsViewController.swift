//
//  SettingsViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import FirebaseAuth
import Kingfisher
import UIKit

// MARK: - SettingsViewController

/// A modern settings screen using UITableView with insetGrouped style to manage user preferences.
final class SettingsViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: SettingsViewModel

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = AppColor.background
        table.translatesAutoresizingMaskIntoConstraints = false
        // Dynamic cell height support
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        return table
    }()

    // MARK: - Initializer

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh profile data every time the user enters settings
        viewModel.fetchUserData()
    }

    // MARK: - Setup UI

    /// Configures the main view appearance and constraints.
    private func setupUI() {
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self

        // Register custom and standard cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(ProfileHeaderCell.self, forCellReuseIdentifier: ProfileHeaderCell.identifier)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Bindings

    /// Connects the ViewModel closures to UI update logic.
    private func bindViewModel() {
        // Refresh table whenever data is fetched or modified
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }

        // Show generic informational alerts
        viewModel.showAlert = { [weak self] title in
            guard let self = self else { return }
            AlertManager.showAlert(title: title, message: "Coming soon!", vc: self)
        }

        // Handle navigation to the Profile Editor
        viewModel.onNavigateToEdit = { [weak self] user in
            let editVM = EditProfileViewModel(user: user)
            let editVC = EditProfileViewController(viewModel: editVM)
            let nav = UINavigationController(rootViewController: editVC)
            nav.modalPresentationStyle = .fullScreen
            self?.present(nav, animated: true)
        }

        // Handle Session teardown via SceneDelegate
        viewModel.onLogout = {
            // AppRouter will handle Firebase sign-out and route to the Login screen
            AppRouter.shared.forceLogout()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = viewModel.sections[indexPath.section].options[indexPath.row]

        // Section 0 is reserved for the Large Profile Header Card
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileHeaderCell.identifier, for: indexPath) as? ProfileHeaderCell else {
                return UITableViewCell()
            }
            let imageUrl = viewModel.currentUser?.profileImageUrl
            cell.configure(title: option.title, subtitle: option.subtitle ?? "Available", imageUrl: imageUrl)
            return cell
        }

        // Standard settings row
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        configureStandardCell(cell, with: option)
        return cell
    }

    /// Helper to style standard settings rows using modern UIListContentConfiguration.
    private func configureStandardCell(_ cell: UITableViewCell, with option: SettingsOption) {
        var content = cell.defaultContentConfiguration()
        content.text = option.title
        content.textProperties.font = AppFont.light.set(size: 16)
        content.textProperties.color = option.titleColor
        content.image = UIImage(systemName: option.iconName)
        content.imageProperties.tintColor = option.iconTintColor
        content.imageToTextPadding = 15

        cell.contentConfiguration = content
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .disclosureIndicator
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard NetworkChecker.isConnected else {
            AlertManager.showAlert(title: "No Internet", message: "Please check your connection and try again.", vc: self)
            return
        }
        // Execute the handler closure associated with the selected option
        viewModel.sections[indexPath.section].options[indexPath.row].handler()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Explicit height for the profile card, automatic for others
        return indexPath.section == 0 ? 120 : UITableView.automaticDimension
    }
}
