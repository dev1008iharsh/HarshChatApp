//
//  SettingsViewController.swift
//  HarshChatApp
//
//  Created by Harsh on 02/03/26.
//

import Kingfisher
import UIKit

final class ProfileHeaderCell: UITableViewCell {
    static let identifier = "ProfileHeaderCell"

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        // Using secondary background for the 'card' look
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 35 // Circle for 70x70
        iv.backgroundColor = .systemGray6
        iv.tintColor = .systemGray4 // Placeholder tint
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        // Using your custom AppFont
        label.font = AppFont.bold.set(size: 18)
        label.textColor = AppColor.primaryText
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular.set(size: 14)
        label.textColor = AppColor.secondaryText
        label.numberOfLines = 3
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var labelStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(profileImageView)
        containerView.addSubview(labelStack)
        containerView.addSubview(chevronImageView)

        // Optimizing constraints to match standard Apple margins
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),

            labelStack.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            labelStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    // MARK: - Configuration

    func configure(title: String, subtitle: String, imageUrl: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        // Show indicator while loading
        profileImageView.kf.indicatorType = .activity

        let placeholder = UIImage(systemName: "person.circle")

        if let urlStr = imageUrl, let url = URL(string: urlStr) {
            // MAJOR EVENT: Optimized Downsampling to 100x100 for fast loading
            let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100))
                |> RoundCornerImageProcessor(cornerRadius: 50)

            profileImageView.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(0.2)), // Shorter fade for 'snappy' feel
                    .cacheOriginalImage,
                ]
            )
        } else {
            profileImageView.image = placeholder
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.kf.cancelDownloadTask()
        profileImageView.image = nil // Clear image to avoid ghosting
    }
}
