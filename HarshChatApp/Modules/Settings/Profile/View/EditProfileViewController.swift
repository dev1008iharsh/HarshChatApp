import Kingfisher
import PhotosUI
import UIKit

final class EditProfileViewController: UIViewController {
    private let viewModel: EditProfileViewModel

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.layer.borderWidth = 3
        iv.layer.borderColor = AppColor.primaryColor.cgColor
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let editIconButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        btn.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = AppColor.primaryColor
        btn.layer.cornerRadius = 18
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let nameField = CustomInputField(title: "Name", placeholder: "Your Name")
    private let bioField = CustomInputField(title: "Bio", placeholder: "About you")
    private let emailField = CustomInputField(title: "Email", placeholder: "email@example.com", keyboard: .emailAddress)
    private let phoneField = CustomInputField(title: "Phone", placeholder: "", keyboard: .phonePad)

    private let genderSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Male", "Female", "Other"])
        sc.selectedSegmentTintColor = AppColor.primaryColor
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        populateData()
        setupActions()
        bindViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [profileImageView, editIconButton, genderSegment].forEach { contentView.addSubview($0) }

        let stackView = UIStackView(arrangedSubviews: [nameField, bioField, emailField, phoneField])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            editIconButton.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 4),
            editIconButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            editIconButton.widthAnchor.constraint(equalToConstant: 36),
            editIconButton.heightAnchor.constraint(equalToConstant: 36),

            stackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            genderSegment.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 25),
            genderSegment.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            genderSegment.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            genderSegment.heightAnchor.constraint(equalToConstant: 45),
            genderSegment.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    private func setupNavigation() {
        title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Update",
            style: .prominent,
            target: self,
            action: #selector(didTapUpdate)
        )
        navigationController?.navigationBar.tintColor = AppColor.primaryColor
    }

    private func populateData() {
        nameField.textField.text = viewModel.name
        bioField.textField.text = viewModel.bio
        emailField.textField.text = viewModel.email
        phoneField.textField.text = viewModel.phone
        phoneField.textField.isEnabled = false

        if let urlString = viewModel.profileImageUrl, let url = URL(string: urlString) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        }

        let genders = ["Male", "Female", "Other"]
        genderSegment.selectedSegmentIndex = genders.firstIndex(of: viewModel.gender) ?? 0
    }

    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        profileImageView.addGestureRecognizer(tap)
        editIconButton.addTarget(self, action: #selector(didTapImage), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onLoadingStatus = { isLoading in
            DispatchQueue.main.async {
                isLoading ? LoaderManager.shared.startLoading() : LoaderManager.shared.stopLoading()
            }
        }

        viewModel.onError = { [weak self] msg in
            DispatchQueue.main.async {
                guard let self = self else { return }
                AlertManager.showAlert(title: "Error", message: msg, vc: self)
            }
        }

        viewModel.onUpdateSuccess = { [weak self] in
            DispatchQueue.main.async { self?.dismiss(animated: true) }
        }
    }

    @objc private func didTapImage() {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func didTapCancel() { dismiss(animated: true) }

    @objc private func didTapUpdate() {
        viewModel.name = nameField.textField.text ?? ""
        viewModel.bio = bioField.textField.text ?? ""
        viewModel.email = emailField.textField.text ?? ""
        viewModel.gender = genderSegment.titleForSegment(at: genderSegment.selectedSegmentIndex) ?? "Other"
        viewModel.profileImageData = profileImageView.image?.jpegData(compressionQuality: 0.7)
        viewModel.saveProfile()
    }
}

extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            DispatchQueue.main.async { self?.profileImageView.image = image as? UIImage }
        }
    }
}

private class CustomInputField: UIView {
    let textField = UITextField()
    init(title: String, placeholder: String, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        let label = UILabel()
        label.text = title
        label.font = AppFont.semiBold.set(size: 14)
        label.textColor = AppColor.secondaryText

        textField.placeholder = placeholder
        textField.font = AppFont.medium.set(size: 16)
        textField.keyboardType = keyboard

        let line = UIView()
        line.backgroundColor = .systemGray5

        [label, textField, line].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
