import UIKit
import Kingfisher

final class ConversationCell: UITableViewCell {
    static let identifier = "ConversationCell"

    // ✅ UI Elements with Custom Fonts & Colors
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 30 // Larger profile picture
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold.set(size: 17) // ✅ Using your Custom Font
        label.textColor = AppColor.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular.set(size: 14) // ✅ Using your Custom Font
        label.textColor = AppColor.secondaryText
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.light.set(size: 12) // ✅ Using your Custom Font
        label.textColor = AppColor.secondaryText
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        setupSelectionStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupSelectionStyle() {
        let bgView = UIView()
        bgView.backgroundColor = AppColor.primaryColor.withAlphaComponent(0.1)
        self.selectedBackgroundView = bgView
        self.backgroundColor = AppColor.background // ✅ Setting your background
    }

    private func setupLayout() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),

            // Time Label (Top Right)
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(equalToConstant: 80),

            // Name Label
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            // Last Message
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with model: Conversation) {
        nameLabel.text = model.otherUserName
        lastMessageLabel.text = model.lastMessage
        
        // ✅ Date Formatting
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(model.timestamp) {
            formatter.dateFormat = "hh:mm a"
        } else {
            formatter.dateFormat = "dd/MM/yy"
        }
        timeLabel.text = formatter.string(from: model.timestamp)

        // Image Handling with Kingfisher
        if let urlStr = model.profileImageUrl, let url = URL(string: urlStr) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            profileImageView.tintColor = .systemGray4
        }
    }
}
