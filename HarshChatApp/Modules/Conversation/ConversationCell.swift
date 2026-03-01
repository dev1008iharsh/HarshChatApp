import UIKit
import Kingfisher

final class ConversationCell: UITableViewCell {
    static let identifier = "ConversationCell"

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 30
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5 // Adaptive gray for placeholder
        iv.tintColor = .systemGray2
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label // ✅ Black in Light mode, White in Dark mode
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel // ✅ Subtle gray that works in both modes
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel // ✅ Even lighter gray for timestamp
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        self.backgroundColor = .systemBackground // ✅ Adapts to Light/Dark background
        self.selectionStyle = .default
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -10),

            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            dateLabel.widthAnchor.constraint(equalToConstant: 85),

            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            lastMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15)
        ])
    }

    func configure(with model: Conversation) {
        nameLabel.text = model.otherUserName
        lastMessageLabel.text = model.lastMessage
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        dateLabel.text = formatter.string(from: model.timestamp)

        if let urlString = model.profileImageUrl, let url = URL(string: urlString) {
            profileImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}
