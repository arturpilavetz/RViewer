//
//  TopUserCell.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 22.02.2026.
//

import UIKit
import SnapKit

final class TopUserCell: UITableViewCell {
	private let cardView: UIView = {
		let view = UIView()
		view.backgroundColor = .secondarySystemBackground
		view.layer.cornerRadius = 12
		view.layer.borderColor = UIColor.systemGray5.cgColor
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
	private static let imageCache = NSCache<NSString, UIImage>()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setConstraints()
		setUpView()
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

	private func setConstraints() {
		contentView.addSubview(cardView)
		cardView.addSubview(avatarImageView)
		cardView.addSubview(usernameLabel)
		cardView.addSubview(reputationLabel)
		cardView.addSubview(locationLabel)
		cardView.addSubview(badgesLabel)

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

	private func setUpView() {
		backgroundColor = .clear
		selectionStyle = .none
	}

	func setData(user: UserItemData) {
		usernameLabel.text = user.displayName ?? "Unknown User"
		reputationLabel.text = "Reputation: \(formattedCount(user.reputation ?? 0))"
		locationLabel.text = user.location?.isEmpty == false ? user.location : "Location not provided"
		badgesLabel.attributedText = badgeText(user.badgeCounts)

		loadImage(urlString: user.profileImage)
	}

	private func badgeText(_ badges: BadgeCounts?) -> NSAttributedString {
		let text = NSMutableAttributedString()

		let gold = NSAttributedString(
			string: "● \(badges?.gold ?? 0)  ",
			attributes: [.foregroundColor: UIColor.systemYellow]
		)
		let silver = NSAttributedString(
			string: "● \(badges?.silver ?? 0)  ",
			attributes: [.foregroundColor: UIColor.systemGray]
		)
		let bronze = NSAttributedString(
			string: "● \(badges?.bronze ?? 0)",
			attributes: [.foregroundColor: UIColor.systemBrown]
		)

		text.append(gold)
		text.append(silver)
		text.append(bronze)
		return text
	}

	private func formattedCount(_ value: Int) -> String {
		if value >= 1_000_000 {
			return String(format: "%.1fm", Double(value) / 1_000_000.0)
		}
		if value >= 1_000 {
			return String(format: "%.1fk", Double(value) / 1_000.0)
		}
		return "\(value)"
	}

	private func loadImage(urlString: String?) {
		guard let urlString,
			  let url = URL(string: urlString) else {
			avatarImageView.image = UIImage(systemName: "person.crop.circle")
			return
		}

		if let cached = Self.imageCache.object(forKey: urlString as NSString) {
			avatarImageView.image = cached
			return
		}

		avatarImageView.image = UIImage(systemName: "person.crop.circle")
		imageTask = Task {
			do {
				let (data, _) = try await URLSession.shared.data(from: url)
				guard !Task.isCancelled,
					  let image = UIImage(data: data) else { return }

				Self.imageCache.setObject(image, forKey: urlString as NSString)

				await MainActor.run {
					self.avatarImageView.image = image
				}
			} catch {
				return
			}
		}
	}
}
