import FirebaseAuth
import Kingfisher
import UIKit

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        table.backgroundColor = .systemGroupedBackground
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        return table
    }()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchUserData()
    }

    private func setupUI() {
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.onDataUpdate = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }

        viewModel.showAlert = { [weak self] title in
            guard let self = self else { return }
            AlertManager.showAlert(title: title, message: "You tapped on \(title). Feature coming soon!", vc: self)
        }

        viewModel.onNavigateToEdit = { [weak self] user in
            let editVM = EditProfileViewModel(user: user)
            let editVC = EditProfileViewController(viewModel: editVM)
            let nav = UINavigationController(rootViewController: editVC)
            nav.modalPresentationStyle = .fullScreen
            self?.present(nav, animated: true)
        }

        viewModel.onLogout = { [weak self] in
            if let sceneDelegate = self?.view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.checkAuthentication()
            }
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        let option = viewModel.sections[indexPath.section].options[indexPath.row]
        
        if indexPath.section == 0 {
            configureProfileCell(cell, with: option, at: indexPath)
        } else {
            configureStandardCell(cell, with: option)
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func configureProfileCell(_ cell: UITableViewCell, with option: SettingsOption, at indexPath: IndexPath) {
        var content = cell.defaultContentConfiguration()
        content.text = option.title
        content.textProperties.font = AppFont.light.set(size: 22)
        content.textProperties.color = AppColor.primaryText
        
        content.secondaryText = option.subtitle ?? "Available"
        content.secondaryTextProperties.font = AppFont.light.set(size: 14)
        content.secondaryTextProperties.color = AppColor.secondaryText
        content.secondaryTextProperties.numberOfLines = 3
        
        let size: CGFloat = 60
        content.imageProperties.maximumSize = CGSize(width: size, height: size)
        content.imageProperties.reservedLayoutSize = CGSize(width: size, height: size)
        content.imageProperties.cornerRadius = size / 2
        content.imageToTextPadding = 15
        content.image = UIImage(systemName: "person.circle.fill")
        
        if let urlString = viewModel.currentUser?.profileImageUrl, let url = URL(string: urlString) {
            let processor = RoundCornerImageProcessor(cornerRadius: 140)
            KingfisherManager.shared.retrieveImage(with: url, options: [.processor(processor)]) { [weak self] result in
                guard let self = self, case .success(let value) = result else { return }
                DispatchQueue.main.async {
                    if let currentCell = self.tableView.cellForRow(at: indexPath) {
                        var updatedContent = currentCell.defaultContentConfiguration()
                        updatedContent.text = content.text
                        updatedContent.textProperties = content.textProperties
                        updatedContent.secondaryText = content.secondaryText
                        updatedContent.secondaryTextProperties = content.secondaryTextProperties
                        updatedContent.imageProperties = content.imageProperties
                        updatedContent.imageToTextPadding = content.imageToTextPadding
                        updatedContent.image = value.image
                        currentCell.contentConfiguration = updatedContent
                    }
                }
            }
        }
        cell.contentConfiguration = content
    }

    private func configureStandardCell(_ cell: UITableViewCell, with option: SettingsOption) {
        var content = cell.defaultContentConfiguration()
        content.text = option.title
        content.textProperties.font = AppFont.light.set(size: 16)
        content.textProperties.color = option.titleColor
        content.image = UIImage(systemName: option.iconName)
        content.imageProperties.tintColor = option.iconTintColor
        cell.contentConfiguration = content
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.sections[indexPath.section].options[indexPath.row].handler()
    }
}

