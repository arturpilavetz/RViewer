//
//  PostDetailsVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 25.02.2026.
//

import UIKit
import SnapKit
import SafariServices

final class PostDetailsVC: UIViewController {
	private let scrollView = UIScrollView()
	private let contentView = UIView()
	private let stackView: UIStackView = {
		let stack = UIStackView()
		stack.axis = .vertical
		stack.spacing = 12
		return stack
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 22)
		label.textColor = .label
		label.numberOfLines = 0
		return label
	}()

	private let metaLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14, weight: .semibold)
		label.textColor = .secondaryLabel
		label.numberOfLines = 0
		return label
	}()

	private let tagsLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 13, weight: .medium)
		label.textColor = .tertiaryLabel
		label.numberOfLines = 0
		return label
	}()

	private let bodyLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 16)
		label.textColor = .label
		label.numberOfLines = 0
		return label
	}()

	private let openInWebButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Open in StackOverflow", for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
		return button
	}()

	private let openAuthorButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Open Author Profile", for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
		return button
	}()

	private let question: QuestionItemData
	private let userDetailsFactory: (UserItemData) -> UIViewController

	init(question: QuestionItemData, userDetailsFactory: @escaping (UserItemData) -> UIViewController) {
		self.question = question
		self.userDetailsFactory = userDetailsFactory
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		title = "Post Details"

		view.addSubview(scrollView)
		scrollView.addSubview(contentView)
		contentView.addSubview(stackView)
		[
			titleLabel,
			metaLabel,
			tagsLabel,
			bodyLabel,
			openAuthorButton,
			openInWebButton
		].forEach { stackView.addArrangedSubview($0) }

		scrollView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

		contentView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
			make.width.equalTo(scrollView.snp.width)
		}

		stackView.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(16)
		}

		openInWebButton.addTarget(self, action: #selector(openInWeb), for: .touchUpInside)
		openAuthorButton.addTarget(self, action: #selector(openAuthorProfile), for: .touchUpInside)
		configure()
	}

	private func configure() {
		titleLabel.text = question.title ?? "Untitled question"
		let author = question.owner?.displayName ?? "Unknown author"
		let score = question.score ?? 0
		let answers = question.answerCount ?? 0
		let views = question.viewCount ?? 0
		let askedDate = UserPresentationFormatter.unixDate(question.creationDate)
		metaLabel.text = "By: \(author)\nScore: \(score) • Answers: \(answers) • Views: \(views)\nAsked: \(askedDate)"

		let tags = (question.tags ?? []).joined(separator: " • ")
		tagsLabel.text = tags.isEmpty ? "Tags: -" : "Tags: \(tags)"

		bodyLabel.text = htmlToPlainText(question.body) ?? "No body available."
		openInWebButton.isHidden = question.link == nil
		openAuthorButton.isHidden = question.owner?.displayName == nil
	}

	@objc private func openInWeb() {
		guard let link = question.link, let url = URL(string: link) else { return }
		let safariVC = SFSafariViewController(url: url)
		present(safariVC, animated: true)
	}

	@objc private func openAuthorProfile() {
		guard let user = makeUserItemFromOwner(question.owner) else { return }
		let userVC = userDetailsFactory(user)
		navigationController?.pushViewController(userVC, animated: true)
	}

	private func makeUserItemFromOwner(_ owner: QuestionOwnerData?) -> UserItemData? {
		guard let owner else { return nil }
		guard owner.userID != nil || owner.accountID != nil || owner.link != nil else { return nil }

		return UserItemData(
			badgeCounts: nil,
			collectives: nil,
			accountID: owner.accountID,
			isEmployee: nil,
			lastModifiedDate: nil,
			lastAccessDate: nil,
			reputationChangeYear: nil,
			reputationChangeQuarter: nil,
			reputationChangeMonth: nil,
			reputationChangeWeek: nil,
			reputationChangeDay: nil,
			reputation: owner.reputation,
			creationDate: nil,
			userType: UserType(rawValueForStorage: owner.userType),
			userID: owner.userID,
			acceptRate: nil,
			location: nil,
			websiteURL: nil,
			link: owner.link,
			profileImage: owner.profileImage,
			displayName: owner.displayName
		)
	}

	private func htmlToPlainText(_ html: String?) -> String? {
		guard let html, let data = html.data(using: .utf8) else { return nil }
		let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
			.documentType: NSAttributedString.DocumentType.html,
			.characterEncoding: String.Encoding.utf8.rawValue
		]
		let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
		let text = attributed?.string.trimmingCharacters(in: .whitespacesAndNewlines)
		return text?.isEmpty == true ? nil : text
	}
}
