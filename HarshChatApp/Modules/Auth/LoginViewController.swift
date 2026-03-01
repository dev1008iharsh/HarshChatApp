import UIKit

final class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel
    private var actionButtonTopConstraint: NSLayoutConstraint?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "app_logo")
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 16
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let mainVectorView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "login_vector")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your phone number"
        label.font = AppFont.bold.set(size: 24)
        label.textColor = AppColor.primaryTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "We'll send a one-time password to verify your identity."
        label.font = AppFont.regular.set(size: 15)
        label.textColor = AppColor.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let phoneInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.systemGray6.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let countryCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "🇮🇳 +91"
        label.font = AppFont.semiBold.set(size: 18)
        label.textColor = AppColor.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let verticalDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 10 digits"
        tf.keyboardType = .numberPad
        tf.font = AppFont.medium.set(size: 19)
        tf.tintColor = AppColor.primaryTeal
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let otpTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 6-digit OTP"
        tf.keyboardType = .numberPad
        tf.font = AppFont.bold.set(size: 20)
        tf.backgroundColor = .secondarySystemGroupedBackground
        tf.layer.cornerRadius = 16
        tf.layer.borderWidth = 1.5
        tf.layer.borderColor = AppColor.primaryTeal.withAlphaComponent(0.3).cgColor
        tf.textAlignment = .center
        tf.tintColor = AppColor.primaryTeal
        tf.alpha = 0
        tf.isHidden = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = AppFont.bold.set(size: 18)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.shadowColor = AppColor.primaryTeal.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.color = .white
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupKeyboardHandling()
        startVectorAnimation()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.background
        phoneTextField.delegate = self
        otpTextField.delegate = self

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [logoImageView, mainVectorView, titleLabel, subtitleLabel, phoneInputContainer, otpTextField, actionButton].forEach {
            contentView.addSubview($0)
        }

        [countryCodeLabel, verticalDivider, phoneTextField].forEach { phoneInputContainer.addSubview($0) }
        actionButton.addSubview(activityIndicator)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 70),
            logoImageView.widthAnchor.constraint(equalToConstant: 70),

            mainVectorView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            mainVectorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mainVectorView.heightAnchor.constraint(equalToConstant: 200),
            mainVectorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            mainVectorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            titleLabel.topAnchor.constraint(equalTo: mainVectorView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            phoneInputContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            phoneInputContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            phoneInputContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            phoneInputContainer.heightAnchor.constraint(equalToConstant: 65),

            countryCodeLabel.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor, constant: 16),
            countryCodeLabel.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            countryCodeLabel.widthAnchor.constraint(equalToConstant: 80),

            verticalDivider.leadingAnchor.constraint(equalTo: countryCodeLabel.trailingAnchor, constant: 12),
            verticalDivider.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            verticalDivider.widthAnchor.constraint(equalToConstant: 1),
            verticalDivider.heightAnchor.constraint(equalToConstant: 30),

            phoneTextField.leadingAnchor.constraint(equalTo: verticalDivider.trailingAnchor, constant: 12),
            phoneTextField.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor, constant: -16),
            phoneTextField.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            phoneTextField.heightAnchor.constraint(equalTo: phoneInputContainer.heightAnchor),

            otpTextField.topAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor, constant: 20),
            otpTextField.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor),
            otpTextField.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor),
            otpTextField.heightAnchor.constraint(equalToConstant: 65),

            actionButton.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
        ])

        actionButtonTopConstraint = actionButton.topAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor, constant: 40)
        actionButtonTopConstraint?.isActive = true
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] isSent in
            DispatchQueue.main.async { self?.animateOTPField(show: isSent) }
        }

        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                guard let self = self else { return }
                isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
                let title = self.otpTextField.isHidden ? "Continue" : "Submit"
                self.actionButton.setTitle(isLoading ? "" : title, for: .normal)
                self.actionButton.isEnabled = !isLoading
            }
        }

        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                guard let self = self, let message = message else { return }
                let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Got it", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    @objc private func handleLogin() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        view.endEditing(true)
        let phoneText = phoneTextField.text ?? ""
        let otpText = otpTextField.text ?? ""
        viewModel.handleMainButtonAction(phoneNumber: "+91\(phoneText)", otpCode: otpText)
    }

    private func animateOTPField(show: Bool) {
        guard show else { return }
        actionButtonTopConstraint?.isActive = false
        actionButtonTopConstraint = actionButton.topAnchor.constraint(equalTo: otpTextField.bottomAnchor, constant: 30)
        actionButtonTopConstraint?.isActive = true
        otpTextField.isHidden = false

        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.otpTextField.alpha = 1
            self.titleLabel.text = "OTP Sent Successfully"
            self.subtitleLabel.text = "Almost there! Enter the 6-digit code sent to your mobile number."
            self.phoneInputContainer.alpha = 0.5
            self.phoneInputContainer.isUserInteractionEnabled = false
            self.view.layoutIfNeeded()
            self.updateButtonStyle()
        } completion: { _ in
            self.otpTextField.becomeFirstResponder()
        }
    }

    private func updateButtonStyle() {
        let isPhoneMode = otpTextField.isHidden
        let count = isPhoneMode ? (phoneTextField.text?.count ?? 0) : (otpTextField.text?.count ?? 0)
        let target = isPhoneMode ? 10 : 6
        let isEnabled = (count == target)

        UIView.animate(withDuration: 0.3) {
            self.actionButton.backgroundColor = isEnabled ? AppColor.primaryTeal : .systemGray4
            self.actionButton.layer.shadowOpacity = isEnabled ? 0.3 : 0
            self.actionButton.transform = isEnabled ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }
    }

    private func startVectorAnimation() {
        mainVectorView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8) {
            self.mainVectorView.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 2.0, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
                self.mainVectorView.transform = CGAffineTransform(translationX: 0, y: -15)
            }
        }
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight + 10, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        scrollView.scrollRectToVisible(actionButton.frame, animated: true)
    }

    @objc private func keyboardWillHide() {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if !string.isEmpty && CharacterSet.decimalDigits.inverted.contains(string.unicodeScalars.first!) { return false }

        let limit = (textField == phoneTextField) ? 10 : 6
        if updatedText.count <= limit {
            textField.text = updatedText
            updateButtonStyle()
            textField.superview?.layer.borderColor = updatedText.count == limit ? AppColor.primaryTeal.cgColor : UIColor.systemGray6.cgColor
        }
        return false
    }
}
