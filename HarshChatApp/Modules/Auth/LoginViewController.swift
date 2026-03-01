//
//  LoginViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 01/03/26.
//

import UIKit

// Managed by Coordinator/ViewModel for navigation and logic
final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: LoginViewModel
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
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
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 20
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
        label.font = AppFont.bold.set(size: 20)
        label.textColor = AppColor.primaryTeal
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "We'll send a one-time password to verify your identity."
        label.font = AppFont.regular.set(size: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let phoneInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let countryCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "+91"
        label.font = AppFont.semiBold.set(size: 18)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let verticalDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 10 digits"
        tf.keyboardType = .numberPad
        tf.font = AppFont.medium.set(size: 18)
        tf.tintColor = .systemGreen
        tf.textAlignment = .left
        tf.contentHorizontalAlignment = .left
        tf.semanticContentAttribute = .forceLeftToRight
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let otpTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 6-digit OTP"
        tf.keyboardType = .numberPad
        tf.font = AppFont.bold.set(size: 18)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 12
        tf.setLeftPaddingPoints(15)
        tf.tintColor = .systemGreen
        tf.alpha = 0
        tf.isHidden = true
        tf.textAlignment = .left
        tf.semanticContentAttribute = .forceLeftToRight
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = AppFont.bold.set(size: 18)
        button.backgroundColor = .systemGray4 // Default state
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: .loginTapped, for: .touchUpInside)
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
    
    // MARK: - Init
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI() // Initialize components
        bindViewModel() // Observe state changes
        setupKeyboardHandling() // Handle scroll offsets
        startVectorAnimation() // Initial popup + floating
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
        
        phoneInputContainer.addSubview(countryCodeLabel)
        phoneInputContainer.addSubview(verticalDivider)
        phoneInputContainer.addSubview(phoneTextField)
        actionButton.addSubview(activityIndicator)
        
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
            
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            
            mainVectorView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            mainVectorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mainVectorView.heightAnchor.constraint(equalToConstant: 180),
            mainVectorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            mainVectorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: mainVectorView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            phoneInputContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            phoneInputContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            phoneInputContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            phoneInputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            countryCodeLabel.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor, constant: 15),
            countryCodeLabel.widthAnchor.constraint(equalToConstant: 40),
            countryCodeLabel.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            
            verticalDivider.leadingAnchor.constraint(equalTo: countryCodeLabel.trailingAnchor, constant: 10),
            verticalDivider.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            verticalDivider.widthAnchor.constraint(equalToConstant: 1),
            verticalDivider.heightAnchor.constraint(equalToConstant: 24),
            
            phoneTextField.leadingAnchor.constraint(equalTo: verticalDivider.trailingAnchor, constant: 10),
            phoneTextField.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor, constant: -10),
            phoneTextField.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),
            phoneTextField.heightAnchor.constraint(equalTo: phoneInputContainer.heightAnchor),
            
            otpTextField.topAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor, constant: 15),
            otpTextField.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor),
            otpTextField.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor),
            otpTextField.heightAnchor.constraint(equalToConstant: 60),
            
            actionButton.topAnchor.constraint(equalTo: otpTextField.bottomAnchor, constant: 25),
            actionButton.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 55),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
    }
    
    // MARK: - Animations
    private func startVectorAnimation() {
        // Initial popup animation
        mainVectorView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8) {
            self.mainVectorView.transform = .identity
        } completion: { _ in
            // Loop floating animation
            UIView.animate(withDuration: 2.0, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
                self.mainVectorView.transform = CGAffineTransform(translationX: 0, y: -15)
            })
        }
    }
    
    private func animateOTPField(show: Bool) {
        guard show else { return }
        self.otpTextField.isHidden = false
        self.otpTextField.alpha = 0
        self.otpTextField.transform = CGAffineTransform(translationX: 0, y: -40).scaledBy(x: 0.9, y: 0.9)
        
        UIView.transition(with: titleLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.titleLabel.text = "OTP Sent Successfully"
            self.subtitleLabel.text = "Almost there! Enter the 6-digit code sent to your mobile number."
        }
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            self.otpTextField.alpha = 1
            self.otpTextField.transform = .identity
            self.updateButtonStyle() // Color update check
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.otpTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - Helper Methods
    private func updateButtonStyle() {
        let isPhoneMode = otpTextField.isHidden
        let count = isPhoneMode ? (phoneTextField.text?.count ?? 0) : (otpTextField.text?.count ?? 0)
        let target = isPhoneMode ? 10 : 6
        
        UIView.animate(withDuration: 0.3) {
            self.actionButton.backgroundColor = (count == target) ? .systemGreen : .systemGray4
        }
    }
     
    // MARK: - Logic & ViewModel Binding
    private func bindViewModel() {
        // Observes when OTP is successfully sent to transition the UI
        viewModel.onStateChange = { [weak self] isSent in
            DispatchQueue.main.async { self?.animateOTPField(show: isSent) }
        }
        
        // Manages the loading state and button appearance
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                guard let self = self else { return }
                isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
                let title = self.otpTextField.isHidden ? "Continue" : "Submit"
                self.actionButton.setTitle(isLoading ? "" : title, for: .normal)
                self.actionButton.isEnabled = !isLoading
            }
        }
        
        // 🔥 Handles validation and API errors by showing alerts
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Displays a user-friendly alert using our AlertManager struct
                AlertManager.showAlert(on: self, type: .custom(message ?? "Something went wrong"))
            }
        }
    }
    
    @objc func handleLogin() {
        view.endEditing(true)
        let isPhoneMode = otpTextField.isHidden
        let phoneText = phoneTextField.text ?? ""
        let otpText = otpTextField.text ?? ""
        
        // Error validation on tap
        if isPhoneMode && phoneText.count != 10 {
            AlertManager.showAlert(on: self, type: .invalidPhone)
            return
        } else if !isPhoneMode && otpText.count != 6 {
            AlertManager.showAlert(on: self, type: .invalidOTP)
            return
        }
        
        let fullPhoneNumber = "+91\(phoneText)"
        viewModel.handleMainButtonAction(phoneNumber: fullPhoneNumber, otpCode: otpText)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() { view.endEditing(true) }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight + 20, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        scrollView.scrollRectToVisible(actionButton.frame, animated: true)
    }
    
    @objc private func keyboardWillHide() {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Only numbers allowed check
        let allowed = CharacterSet.decimalDigits
        if !string.isEmpty && string.rangeOfCharacter(from: allowed.inverted) != nil { return false }
        
        // Limit and Update Button Color
        if textField == phoneTextField {
            if updatedText.count <= 10 {
                textField.text = updatedText
                updateButtonStyle()
                return false
            }
        } else if textField == otpTextField {
            if updatedText.count <= 6 {
                textField.text = updatedText
                updateButtonStyle()
                return false
            }
        }
        return false
    }
}

// MARK: - Selectors
private extension Selector {
    static let loginTapped = #selector(LoginViewController.handleLogin)
}
