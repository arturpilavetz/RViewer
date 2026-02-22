//
//  StackOverflowTopUsers.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import Foundation

struct StackOverflowTopUsers: Codable {
	let users: [UserItemData]?
	let hasMore: Bool?
	let quotaMax, quotaRemaining: Int?

	enum CodingKeys: String, CodingKey {
		case users = "items"
		case hasMore = "has_more"
		case quotaMax = "quota_max"
		case quotaRemaining = "quota_remaining"
	}
}

// MARK: - UserItemData
struct UserItemData: Codable {
	let badgeCounts: BadgeCounts?
	let collectives: [CollectiveElement]?
	let accountID: Int?
	let isEmployee: Bool?
	let lastModifiedDate, lastAccessDate, reputationChangeYear, reputationChangeQuarter: Int?
	let reputationChangeMonth, reputationChangeWeek, reputationChangeDay, reputation: Int?
	let creationDate: Int?
	let userType: UserType?
	let userID: Int?
	let acceptRate: Int?
	let location: String?
	let websiteURL, link: String?
	let profileImage, displayName: String?

	enum CodingKeys: String, CodingKey {
		case badgeCounts = "badge_counts"
		case collectives
		case accountID = "account_id"
		case isEmployee = "is_employee"
		case lastModifiedDate = "last_modified_date"
		case lastAccessDate = "last_access_date"
		case reputationChangeYear = "reputation_change_year"
		case reputationChangeQuarter = "reputation_change_quarter"
		case reputationChangeMonth = "reputation_change_month"
		case reputationChangeWeek = "reputation_change_week"
		case reputationChangeDay = "reputation_change_day"
		case reputation
		case creationDate = "creation_date"
		case userType = "user_type"
		case userID = "user_id"
		case acceptRate = "accept_rate"
		case location
		case websiteURL = "website_url"
		case link
		case profileImage = "profile_image"
		case displayName = "display_name"
	}
}

// MARK: - BadgeCounts
struct BadgeCounts: Codable {
	let bronze, silver, gold: Int?
}

// MARK: - CollectiveElement
struct CollectiveElement: Codable {
	let collective: CollectiveCollective?
	let role: Role?
}

// MARK: - CollectiveCollective
struct CollectiveCollective: Codable {
	let tags: [String]?
	let externalLinks: [ExternalLink]?
	let description, link, name, slug: String?

	enum CodingKeys: String, CodingKey {
		case tags
		case externalLinks = "external_links"
		case description, link, name, slug
	}
}

// MARK: - ExternalLink
struct ExternalLink: Codable {
	let type: TypeEnum?
	let link: String?
}

enum TypeEnum: String, Codable {
	case support = "support"
}

enum Role: String, Codable {
	case limitedRecognizedMember = "limited_recognized_member"
	case member = "member"
	case recognizedMember = "recognized_member"
}

enum UserType: Codable {
	case registered
	case moderator
	case unregistered
	case teamAdmin
	case doesNotExist
	case unknown(String)

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)

		switch rawValue {
			case "registered":
				self = .registered
			case "moderator":
				self = .moderator
			case "unregistered":
				self = .unregistered
			case "team_admin":
				self = .teamAdmin
			case "does_not_exist":
				self = .doesNotExist
			default:
				self = .unknown(rawValue)
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
			case .registered:
				try container.encode("registered")
			case .moderator:
				try container.encode("moderator")
			case .unregistered:
				try container.encode("unregistered")
			case .teamAdmin:
				try container.encode("team_admin")
			case .doesNotExist:
				try container.encode("does_not_exist")
			case .unknown(let raw):
				try container.encode(raw)
		}
	}
}
