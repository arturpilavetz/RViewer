//
//  SavedUserMapper.swift
//  RedditViewer
//

import Foundation

extension UserItemData {
	var persistenceIdentifier: String? {
		if let userID {
			return "user:\(userID)"
		}
		if let accountID {
			return "account:\(accountID)"
		}
		if let link, !link.isEmpty {
			return "link:\(link)"
		}
		return nil
	}
}

extension SavedUserObject {
	var asUserItemData: UserItemData {
		UserItemData(
			badgeCounts: BadgeCounts(bronze: badgeBronze, silver: badgeSilver, gold: badgeGold),
			collectives: nil,
			accountID: accountID,
			isEmployee: nil,
			lastModifiedDate: lastModifiedDate,
			lastAccessDate: lastAccessDate,
			reputationChangeYear: nil,
			reputationChangeQuarter: nil,
			reputationChangeMonth: nil,
			reputationChangeWeek: nil,
			reputationChangeDay: nil,
			reputation: reputation,
			creationDate: creationDate,
			userType: UserType(rawValueForStorage: userTypeRaw),
			userID: userID,
			acceptRate: acceptRate,
			location: location,
			websiteURL: websiteURL,
			link: link,
			profileImage: profileImage,
			displayName: displayName
		)
	}
}

extension UserType {
	var rawValueForStorage: String {
		switch self {
			case .registered:
				return "registered"
			case .moderator:
				return "moderator"
			case .unregistered:
				return "unregistered"
			case .teamAdmin:
				return "team_admin"
			case .doesNotExist:
				return "does_not_exist"
			case .unknown(let raw):
				return raw
		}
	}

	init?(rawValueForStorage rawValue: String?) {
		guard let rawValue else { return nil }
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
}
