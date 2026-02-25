//
//  PostCell.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 25.02.2026.
//

import UIKit
import SnapKit

final class PostCell: UITableViewCell {
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
		imageView.layer.cornerRadius = 18
		return imageView
	}()

	private let authorLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 12, weight: .semibold)
		label.textColor = .secondaryLabel
		return label
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 17, weight: .bold)
		label.textColor = .label
		label.numberOfLines = 3
		return label
	}()

	private let metaLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 12, weight: .regular)
		label.textColor = .tertiaryLabel
		label.numberOfLines = 2
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
		authorLabel.text = nil
		titleLabel.text = nil
		metaLabel.text = nil
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
		cardView.addSubviews([avatarImageView, authorLabel, titleLabel, metaLabel])

		cardView.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
		}

		avatarImageView.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(12)
			make.top.equalToSuperview().offset(12)
			make.size.equalTo(CGSize(width: 36, height: 36))
		}

		authorLabel.snp.makeConstraints { make in
			make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
			make.centerY.equalTo(avatarImageView)
			make.trailing.equalToSuperview().inset(12)
		}

		titleLabel.snp.makeConstraints { make in
			make.top.equalTo(avatarImageView.snp.bottom).offset(10)
			make.leading.trailing.equalToSuperview().inset(12)
		}

		metaLabel.snp.makeConstraints { make in
			make.top.equalTo(titleLabel.snp.bottom).offset(8)
			make.leading.trailing.equalToSuperview().inset(12)
			make.bottom.equalToSuperview().inset(12)
		}
	}

	func setData(question: QuestionItemData) {
		authorLabel.text = question.owner?.displayName ?? "Unknown author"
		titleLabel.text = question.title ?? "Untitled question"

		let score = question.score ?? 0
		let answers = question.answerCount ?? 0
		let views = question.viewCount ?? 0
		let date = UserPresentationFormatter.unixDate(question.creationDate)
		metaLabel.text = "Score: \(score) • Answers: \(answers) • Views: \(views)\nAsked: \(date)"

		loadImage(urlString: question.owner?.profileImage)
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
