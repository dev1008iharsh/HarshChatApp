//
//  ChatViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import InputBarAccessoryView
import Kingfisher
import MessageKit
import UIKit

// MARK: - CustomTitleView

/// This class is a fix for iOS Navigation Bar.
/// It tells the Nav Bar: "I want to take as much space as possible so I can align my profile image properly."
final class CustomTitleView: UIView {
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
}

// MARK: - ChatViewController

/// The heart of the Chat Module. It inherits from 'MessagesViewController' (from MessageKit).
/// This controller handles displaying messages, sending text/images, and the chat UI.
final class ChatViewController: MessagesViewController, MessageCellDelegate {
    // MARK: - Properties

    // The logic provider (ViewModel) that talks to Firebase.
    private let viewModel: ChatViewModel

    // Native iOS Image Picker to select photos from Gallery or Camera.
    private let imagePicker = UIImagePickerController()

    // The '+' button on the left side of the input bar to send attachments.
    private let plusButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus"), for: .normal)
        btn.tintColor = AppColor.primaryColor
        return btn
    }()

    // MARK: - Initializer

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        // Hides the TabBar (Home, Settings, etc.) when we enter a specific chat.
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationAppearance() // 1. Set Nav Bar colors
        setupUI() // 2. Set CollectionView settings
        setupCustomHeader() // 3. Create the User Profile top header
        setupInputBar() // 4. Design the typing area
        bindViewModel() // 5. Connect UI to Data

        // Start listening to Firestore for new messages in real-time.
        viewModel.listenForMessages()
    }

    // MARK: - Setup Methods

    /// Configures the Navigation Bar color and removes the bottom thin line.
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.background
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    /// Sets up the CollectionView where message bubbles are displayed.
    private func setupUI() {
        view.backgroundColor = AppColor.background
        messagesCollectionView.backgroundColor = AppColor.background

        // These delegates tell MessageKit: "Ask ME how to show the data."
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self

        // Fix for layout issues when the keyboard appears.
        extendedLayoutIncludesOpaqueBars = true

        // Removing user avatars (profile circles) next to every message bubble for a cleaner look.
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        }
    }

    /// Creates a custom view for the Navigation Bar that shows the Name, Phone, and Profile Pic.
    private func setupCustomHeader() {
        let headerContainer = CustomTitleView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        // Profile Image setup
        let profileImageView = UIImageView()
        profileImageView.tintColor = .systemGray4
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 18 // Makes it a 36x36 circle.
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.isUserInteractionEnabled = true
        // Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderImageTap(_:)))
        profileImageView.addGestureRecognizer(tapGesture)
        // Loading image using Kingfisher.
        if let urlStr = viewModel.otherUser.profileImageUrl, let url = URL(string: urlStr) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }

        // Name and Phone Labels
        let nameLabel = UILabel()
        nameLabel.text = viewModel.otherUser.displayName
        nameLabel.font = AppFont.bold.set(size: 16)
        nameLabel.textColor = AppColor.primaryText

        let phoneLabel = UILabel()
        phoneLabel.text = viewModel.otherUser.phoneNumber
        phoneLabel.font = AppFont.regular.set(size: 11)
        phoneLabel.textColor = AppColor.secondaryText

        // Vertical stack for Name and Phone
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        labelStack.axis = .vertical
        labelStack.alignment = .leading

        // Horizontal stack to put Image and LabelStack side-by-side
        let mainStack = UIStackView(arrangedSubviews: [profileImageView, labelStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 10
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        headerContainer.addSubview(mainStack)

        // Auto Layout for the header content.
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 36),
            profileImageView.heightAnchor.constraint(equalToConstant: 36),

            mainStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            mainStack.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
        ])

        navigationItem.titleView = headerContainer
    }

    // MARK: - Actions

    @objc private func handleHeaderImageTap(_ sender: UITapGestureRecognizer) {
        guard let tappedImageView = sender.view as? UIImageView else { return }

        print("🖼️ DEBUG: Header Profile Image tapped")
        view.endEditing(true)
        ImageViewerManager.shared.showFullScreen(from: tappedImageView)
    }

    /// Customizes the Input Bar (where the user types the message).
    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.backgroundView.backgroundColor = AppColor.background

        // Styling the text input field
        messageInputBar.inputTextView.placeholder = "Message"
        messageInputBar.inputTextView.tintColor = AppColor.primaryColor
        messageInputBar.inputTextView.font = AppFont.regular.set(size: 16)
        messageInputBar.inputTextView.backgroundColor = .systemGray6
        messageInputBar.inputTextView.layer.cornerRadius = 20
        messageInputBar.inputTextView.layer.masksToBounds = true

        // Adding padding inside the text field
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 15)

        // Styling the 'Send' button
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane.fill", withConfiguration: sendConfig)
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.tintColor = AppColor.primaryColor

        // Setting up the '+' button on the left side
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        let leftItem = InputBarButtonItem()
        leftItem.setSize(CGSize(width: 40, height: 40), animated: false)
        leftItem.addSubview(plusButton)
        plusButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

        messageInputBar.setLeftStackViewWidthConstant(to: 45, animated: false)
        messageInputBar.setStackViewItems([leftItem], forStack: .left, animated: false)
    }

    /// Handles the '+' button click.
    @objc private func didTapPlus() {
        messageInputBar.inputTextView.resignFirstResponder() // Hide keyboard
        presentActionSheet() // Show Camera/Gallery options
    }

    /// Listens for data changes in ViewModel and reloads the chat.
    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] in
            DispatchQueue.main.async {
                // Refresh the list and automatically scroll to the newest message at the bottom.
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }
}

// MARK: - MessageKit Delegates

// These methods define HOW the messages look.
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    // Who is the person using the app right now?
    var currentSender: SenderType { viewModel.currentUser }

    // Which message object belongs to this row?
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    // Total count of messages.
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    // Show the timestamp (time) below each bubble.
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return NSAttributedString(string: formatter.string(from: message.sentDate), attributes: [
            .font: AppFont.light.set(size: 10),
            .foregroundColor: AppColor.secondaryText,
        ])
    }

    // Align timestamp based on sender (Left for incoming, Right for outgoing).
    func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        return isFromCurrentSender(message: message) ?
            .init(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)) :
            .init(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
    }

    // Bubble Color (Blue for me, Gray for others).
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? AppColor.outgoingBubble : AppColor.incomingBubble
    }

    // Bubble Shape (Tail position).
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubbleTail(isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft, .curved)
    }

    // Responsible for link/phone/email colors inside the bubble
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: isFromCurrentSender(message: message) ? UIColor.white : AppColor.primaryColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }

    // Text Color inside bubbles.
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return AppColor.primaryText
    }

    func textMessageFont(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIFont {
        return AppFont.regular.set(size: 16)
    }

    // Space for the time label below the bubble.
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }

    // Logic to download and display image messages.
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard case let .photo(mediaItem) = message.kind, let url = mediaItem.url else { return }
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url)
    }

    // Open full-screen image viewer when a photo message is tapped.
    func didTapImage(in cell: MessageCollectionViewCell) {
        if let mediaCell = cell as? MediaMessageCell {
            view.endEditing(true)
            ImageViewerManager.shared.showFullScreen(from: mediaCell.imageView)
        }
    }
}

// MARK: - Input Bar & Image Picker Extension

// Handles selecting and sending content.
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, InputBarAccessoryViewDelegate {
    /// Shows a popup to choose between Camera or Photo Library.
    private func presentActionSheet() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Camera", style: .default) { _ in self.openSource(.camera) })
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in self.openSource(.photoLibrary) })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func openSource(_ source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        imagePicker.delegate = self
        imagePicker.sourceType = source
        present(imagePicker, animated: true)
    }

    /// Delegate method called after the user selects an image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        // Extract the selected image and convert it to Data (compressed JPEG).
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.2) else { return }

        // Show loading spinner while uploading.
        LoaderManager.shared.startLoading()

        // Upload image to Firebase.
        viewModel.sendImage(data) { [weak self] in
            DispatchQueue.main.async {
                LoaderManager.shared.stopLoading()
                self?.messageInputBar.inputTextView.resignFirstResponder()
            }
        }
    }

    /// Delegate method called when the 'Send' button is pressed.
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Send text to Firebase.
        viewModel.sendText(trimmed)

        // Clear the input field for the next message.
        inputBar.inputTextView.text = ""
    }
}
