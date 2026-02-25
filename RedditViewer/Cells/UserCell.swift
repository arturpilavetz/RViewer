//
//  UserCell.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 22.02.2026.
//

import UIKit
import SnapKit

final class UserCell: UITableViewCell {
	private let cardView: UIView = {
		let view = UIView()
		view.backgroundColor = .secondarySystemBackground
		view.layer.cornerRadius = 12
		view.layer.borderWidth = 1
		return view
	}()

	private let avatarImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.backgroundColor = .systemGray5
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 24
		return imageView
	}()

	private let usernameLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 17)
		label.textColor = .label
		label.numberOfLines = 1
		return label
	}()

	private let reputationLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14, weight: .semibold)
		label.textColor = .secondaryLabel
		return label
	}()

	private let locationLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 13)
		label.textColor = .tertiaryLabel
		label.numberOfLines = 1
		return label
	}()

	private let badgesLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 13, weight: .medium)
		label.textColor = .secondaryLabel
		return label
	}()

	private var imageTask: Task<Void, Never>?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setConstraints()
		setUpView()
		updateColors()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		imageTask?.cancel()
		imageTask = nil
		avatarImageView.image = nil
		usernameLabel.text = nil
		reputationLabel.text = nil
		locationLabel.text = nil
		badgesLabel.attributedText = nil
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
	}

	private func setUpView() {
		backgroundColor = .clear
		selectionStyle = .none
	}

	private func updateColors() {
		cardView.layer.borderColor = UIColor.separator.cgColor
	}
	
	private func setConstraints() {
		contentView.addSubview(cardView)
		cardView.addSubviews([
			avatarImageView,
			usernameLabel,
			reputationLabel,
			locationLabel,
			badgesLabel
		])

		cardView.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
		}

		avatarImageView.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(12)
			make.top.equalToSuperview().offset(12)
			make.size.equalTo(CGSize(width: 48, height: 48))
		}

		usernameLabel.snp.makeConstraints { make in
			make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
			make.top.equalToSuperview().offset(12)
			make.trailing.equalToSuperview().inset(12)
		}

		reputationLabel.snp.makeConstraints { make in
			make.leading.equalTo(usernameLabel)
			make.top.equalTo(usernameLabel.snp.bottom).offset(4)
			make.trailing.equalToSuperview().inset(12)
		}

		locationLabel.snp.makeConstraints { make in
			make.leading.equalTo(usernameLabel)
			make.top.equalTo(reputationLabel.snp.bottom).offset(4)
			make.trailing.equalToSuperview().inset(12)
		}

		badgesLabel.snp.makeConstraints { make in
			make.leading.equalTo(usernameLabel)
			make.top.equalTo(locationLabel.snp.bottom).offset(8)
			make.trailing.lessThanOrEqualToSuperview().inset(12)
			make.bottom.equalToSuperview().inset(12)
		}
	}

	func setData(user: UserItemData) {
		usernameLabel.text = user.displayName ?? "Unknown User"
		reputationLabel.text = "Reputation: \(UserPresentationFormatter.compactCount(user.reputation ?? 0))"
		locationLabel.text = user.location?.isEmpty == false ? user.location : "Location not provided"
		badgesLabel.attributedText = UserPresentationFormatter.badgesText(user.badgeCounts)

		loadImage(urlString: user.profileImage)
	}

	private func loadImage(urlString: String?) {
		avatarImageView.image = UIImage(systemName: "person.crop.circle")
		imageTask = Task {
			let image = await AvatarImageLoader.shared.image(for: urlString)
			guard !Task.isCancelled else { return }
			await MainActor.run {
				self.avatarImageView.image = image ?? UIImage(systemName: "person.crop.circle")
			}
		}
	}
}
