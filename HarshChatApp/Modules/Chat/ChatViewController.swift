import UIKit
import MessageKit
import InputBarAccessoryView
import Kingfisher

final class ChatViewController: MessagesViewController {
    
    private let viewModel: ChatViewModel
    private let imagePicker = UIImagePickerController()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInputBar()
        bindViewModel()
        viewModel.listenForMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        messagesCollectionView.scrollToLastItem(animated: true)
    }

    private func setupUI() {
        title = "Chat"
        view.backgroundColor = .systemBackground
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnInputBarHeightChanged = true
        
        messagesCollectionView.backgroundColor = AppColor.background
        messagesCollectionView.keyboardDismissMode = .interactive
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.photoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.photoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        }
    }

    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Message"
        messageInputBar.inputTextView.font = AppFont.regular.set(size: 16)
        
        messageInputBar.sendButton.setTitle(nil, for: .normal)
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane.fill")
        messageInputBar.sendButton.tintColor = AppColor.primaryTeal
        
        let attachmentButton = InputBarButtonItem()
        attachmentButton.image = UIImage(systemName: "plus")
        attachmentButton.tintColor = AppColor.primaryTeal
        attachmentButton.setSize(CGSize(width: 35, height: 35), animated: false)
        attachmentButton.onTouchUpInside { [weak self] _ in self?.presentActionSheet() }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 40, animated: false)
        messageInputBar.setStackViewItems([attachmentButton], forStack: .left, animated: false)
    }

    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

    private func presentActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in self.showPicker(source: .camera) }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in self.showPicker(source: .photoLibrary) }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }

    private func showPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        imagePicker.delegate = self
        imagePicker.sourceType = source
        present(imagePicker, animated: true)
    }
}

extension ChatViewController: MessagesDataSource {
    var currentSender: SenderType { viewModel.currentUser }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? AppColor.outgoingBubble : AppColor.incomingBubble
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard case let .photo(media) = message.kind, let url = media.url else { return }
        
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage,
                .loadDiskFileSynchronously
            ]
        )
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }

    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        viewModel.sendText(trimmedText)
        inputBar.inputTextView.text = ""
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.7) {
            viewModel.sendImage(data)
        }
    }
}
