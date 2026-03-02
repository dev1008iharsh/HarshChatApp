//
//  ConversationCell.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//  🌐 Portfolio → https://dev1008iharsh.github.io/
//

import Kingfisher
import UIKit

// MARK: - ConversationCell

/// A custom UITableViewCell designed to display a preview of a chat conversation.
/// It includes a profile picture, user name, last message, and the timestamp.
final class ConversationCell: UITableViewCell {
    // Unique identifier for cell reuse mechanism.
    static let identifier = "ConversationCell"

    // MARK: - UI Elements

    /// Displays the profile image of the other user.
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .systemGray4
        iv.layer.cornerRadius = 30 // Half of 60 to make it perfectly circular.
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray4
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false // Enabling Auto Layout.
        return iv
    }()

    /// Displays the name of the user you are chatting with.
    private let nameLabel: UILabel = {
        let label = UILabel()
        // Using custom AppFont extension for consistent branding.
        label.font = AppFont.bold.set(size: 17)
        label.textColor = AppColor.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Displays a short snippet of the last message sent or received.
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular.set(size: 14)
        label.textColor = AppColor.secondaryText
        label.numberOfLines = 2 // Keeps the UI clean by showing only one line.
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Displays the time or date of the last message in the top-right corner.
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.light.set(size: 12)
        label.textColor = AppColor.secondaryText
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        setupSelectionStyle()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleProfileImageTap() {
        print("🖼️ DEBUG: Profile image tapped in cell")
        // MAJOR EVENT: Call the singleton manager to show full screen
        ImageViewerManager.shared.showFullScreen(from: profileImageView)
    }

    // MARK: - Setup Methods

    private func setupGestures() {
        // Create the tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap))
        // Attach it to the profile image view
        profileImageView.addGestureRecognizer(tap)
    }

    /// Configures the appearance of the cell when a user taps on it.
    private func setupSelectionStyle() {
        let bgView = UIView()
        bgView.backgroundColor = AppColor.primaryColor.withAlphaComponent(0.1)
        selectedBackgroundView = bgView
        backgroundColor = AppColor.background // Applying app-wide background color.
    }

    /// Adds UI elements to the content view and sets up Auto Layout constraints.
    private func setupLayout() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            // Profile Image Constraints: Fixed size and centered vertically.
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),

            // Time Label Constraints: Positioned at the top right.
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(equalToConstant: 80),

            // Name Label Constraints: Positioned next to profile image.
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            // Last Message Constraints: Positioned below the name label.
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            lastMessageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Configuration

    /// Populates the cell with data from the Conversation model.
    /// - Parameter model: The data source containing message and user details.
    func configure(with model: Conversation) {
        nameLabel.text = model.otherUserName
        lastMessageLabel.text = model.lastMessage

        // Smart Date Formatting: Shows time for today, and date for older messages.
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(model.timestamp) {
            formatter.dateFormat = "hh:mm a"
        } else {
            formatter.dateFormat = "dd/MM/yy"
        }
        timeLabel.text = formatter.string(from: model.timestamp)

        // Image Handling using Kingfisher for asynchronous downloading and caching.
        if let urlStr = model.profileImageUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.crop.circle.fill"),
                options: [.transition(.fade(0.3))] // Smooth fade-in effect.
            )
        } else {
            // Fallback to placeholder if no URL is provided.
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray4
        }
    }
}
