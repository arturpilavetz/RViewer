//
//  StackOverflowQuestionsResponse.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 25.02.2026.
//

import Foundation

struct StackOverflowQuestionsResponse: Codable {
	let questions: [QuestionItemData]?
	let hasMore: Bool?
	let quotaMax, quotaRemaining: Int?

	enum CodingKeys: String, CodingKey {
		case questions = "items"
		case hasMore = "has_more"
		case quotaMax = "quota_max"
		case quotaRemaining = "quota_remaining"
	}
}

struct QuestionItemData: Codable {
	let tags: [String]?
	let owner: QuestionOwnerData?
	let isAnswered: Bool?
	let viewCount: Int?
	let answerCount: Int?
	let score: Int?
	let creationDate: Int?
	let questionID: Int?
	let link: String?
	let title: String?
	let body: String?

	enum CodingKeys: String, CodingKey {
		case tags, owner, score, link, title, body
		case isAnswered = "is_answered"
		case viewCount = "view_count"
		case answerCount = "answer_count"
		case creationDate = "creation_date"
		case questionID = "question_id"
	}
}

struct QuestionOwnerData: Codable {
	let accountID: Int?
	let reputation: Int?
	let userID: Int?
	let userType: String?
	let profileImage: String?
	let displayName: String?
	let link: String?

	enum CodingKeys: String, CodingKey {
		case accountID = "account_id"
		case reputation
		case userID = "user_id"
		case userType = "user_type"
		case profileImage = "profile_image"
		case displayName = "display_name"
		case link
	}
}
