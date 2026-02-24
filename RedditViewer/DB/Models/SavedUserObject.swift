//
//  SavedUserObject.swift
//  RedditViewer
//

import Foundation
import RealmSwift

final class SavedUserObject: Object {
	@Persisted(primaryKey: true) var id: String
	@Persisted var accountID: Int?
	@Persisted var userID: Int?
	@Persisted var acceptRate: Int?
	@Persisted var location: String?
	@Persisted var websiteURL: String?
	@Persisted var link: String?
	@Persisted var profileImage: String?
	@Persisted var displayName: String?
	@Persisted var reputation: Int?
	@Persisted var creationDate: Int?
	@Persisted var lastAccessDate: Int?
	@Persisted var lastModifiedDate: Int?
	@Persisted var userTypeRaw: String?
	@Persisted var badgeBronze: Int?
	@Persisted var badgeSilver: Int?
	@Persisted var badgeGold: Int?
	@Persisted var savedAt: Date = Date()
}
