import UIKit
import MessageKit
import InputBarAccessoryView
import Kingfisher

// ✅ Custom View to fix the spacing issue in Navigation Bar
final class CustomTitleView: UIView {
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
}

final class ChatViewController: MessagesViewController, MessageCellDelegate {
    
    private let viewModel: ChatViewModel
    private let imagePicker = UIImagePickerController()
    
    private let plusButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus"), for: .normal)
        btn.tintColor = AppColor.primaryColor
        return btn
    }()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationAppearance()
        setupUI()
        setupCustomHeader()
        setupInputBar()
        bindViewModel()
        viewModel.listenForMessages()
    }
    
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.background
        appearance.shadowColor = .clear // Optional: removes the line under nav bar
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupUI() {
        view.backgroundColor = AppColor.background
        messagesCollectionView.backgroundColor = AppColor.background
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        extendedLayoutIncludesOpaqueBars = true
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        }
    }

    private func setupCustomHeader() {
        // ✅ Key Fix: Use CustomTitleView instead of plain UIView
        let headerContainer = CustomTitleView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 18
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let urlStr = viewModel.otherUser.profileImageUrl, let url = URL(string: urlStr) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
        
        let nameLabel = UILabel()
        nameLabel.text = viewModel.otherUser.displayName
        nameLabel.font = AppFont.bold.set(size: 16)
        nameLabel.textColor = .label
        
        let phoneLabel = UILabel()
        phoneLabel.text = viewModel.otherUser.phoneNumber
        phoneLabel.font = AppFont.regular.set(size: 11)
        phoneLabel.textColor = AppColor.secondaryText
        
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        labelStack.axis = .vertical
        labelStack.alignment = .leading
        
        let mainStack = UIStackView(arrangedSubviews: [profileImageView, labelStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 10
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainer.addSubview(mainStack)
        
        // ✅ Constraints: Leading constant -15 or more to remove the gap
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 36),
            profileImageView.heightAnchor.constraint(equalToConstant: 36),
            
            mainStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            mainStack.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor)
        ])
        
        navigationItem.titleView = headerContainer
    }

    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.backgroundView.backgroundColor = AppColor.background
        
        messageInputBar.inputTextView.placeholder = "Message"
        messageInputBar.inputTextView.tintColor = AppColor.primaryColor
        messageInputBar.inputTextView.font = AppFont.regular.set(size: 16)
        messageInputBar.inputTextView.backgroundColor = .systemGray6
        messageInputBar.inputTextView.layer.cornerRadius = 20
        messageInputBar.inputTextView.layer.masksToBounds = true
        
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 15)
        
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane.fill", withConfiguration: sendConfig)
        messageInputBar.sendButton.setTitle("", for: .normal)
        messageInputBar.sendButton.tintColor = AppColor.primaryColor

        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        let leftItem = InputBarButtonItem()
        leftItem.setSize(CGSize(width: 40, height: 40), animated: false)
        leftItem.addSubview(plusButton)
        plusButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        messageInputBar.setLeftStackViewWidthConstant(to: 45, animated: false)
        messageInputBar.setStackViewItems([leftItem], forStack: .left, animated: false)
    }

    @objc private func didTapPlus() {
        messageInputBar.inputTextView.resignFirstResponder()
        presentActionSheet()
    }

    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }
}

// MARK: - MessageKit Delegates (DataSource, Display, Layout)
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    
    var currentSender: SenderType { viewModel.currentUser }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return NSAttributedString(string: formatter.string(from: message.sentDate), attributes: [
            .font: AppFont.light.set(size: 10),
            .foregroundColor: AppColor.secondaryText
        ])
    }

    func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        return isFromCurrentSender(message: message) ?
            .init(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)) :
            .init(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
    }

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? AppColor.outgoingBubble : AppColor.incomingBubble
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubbleTail(isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft, .curved)
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : AppColor.primaryText
    }

    func textMessageFont(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIFont {
        return AppFont.regular.set(size: 16)
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }

    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard case let .photo(mediaItem) = message.kind, let url = mediaItem.url else { return }
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url)
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        if let mediaCell = cell as? MediaMessageCell {
            ImageViewerManager.shared.showFullScreen(from: mediaCell.imageView)
        }
    }
}

// MARK: - Input Bar & Image Picker
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, InputBarAccessoryViewDelegate {
    
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.6) else { return }
        
        LoaderManager.shared.startLoading()
        
        viewModel.sendImage(data) { [weak self] in
            DispatchQueue.main.async {
                LoaderManager.shared.stopLoading()
                self?.messageInputBar.inputTextView.resignFirstResponder()
            }
        }
    }

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendText(trimmed)
        inputBar.inputTextView.text = ""
    }
}
