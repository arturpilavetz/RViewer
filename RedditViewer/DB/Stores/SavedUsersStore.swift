//
//  SavedUsersStore.swift
//  RedditViewer
//

import Foundation
import RealmSwift

enum SavedUsersStoreError: Error {
	case missingUserIdentifier
}

protocol SavedUsersStoring {
	func fetchUsers() -> [UserItemData]
	func isSaved(user: UserItemData) -> Bool
	func save(user: UserItemData) throws
	func remove(user: UserItemData) throws
	func remove(id: String) throws
}

final class SavedUsersStore: SavedUsersStoring {
	static let shared = SavedUsersStore()

	private init() { }

	func fetchUsers() -> [UserItemData] {
		do {
			let realm = try Realm()
			return realm.objects(SavedUserObject.self)
				.sorted(byKeyPath: "savedAt", ascending: false)
				.map(\.asUserItemData)
		} catch {
			return []
		}
	}

	func isSaved(user: UserItemData) -> Bool {
		guard let id = user.persistenceIdentifier else { return false }
		do {
			let realm = try Realm()
			return realm.object(ofType: SavedUserObject.self, forPrimaryKey: id) != nil
		} catch {
			return false
		}
	}

	func save(user: UserItemData) throws {
		guard let id = user.persistenceIdentifier else {
			throw SavedUsersStoreError.missingUserIdentifier
		}

		let object = SavedUserObject()
		object.id = id
		object.accountID = user.accountID
		object.userID = user.userID
		object.acceptRate = user.acceptRate
		object.location = user.location
		object.websiteURL = user.websiteURL
		object.link = user.link
		object.profileImage = user.profileImage
		object.displayName = user.displayName
		object.reputation = user.reputation
		object.creationDate = user.creationDate
		object.lastAccessDate = user.lastAccessDate
		object.lastModifiedDate = user.lastModifiedDate
		object.userTypeRaw = user.userType?.rawValueForStorage
		object.badgeBronze = user.badgeCounts?.bronze
		object.badgeSilver = user.badgeCounts?.silver
		object.badgeGold = user.badgeCounts?.gold
		object.savedAt = Date()

		let realm = try Realm()
		try realm.write {
			realm.add(object, update: .modified)
		}
	}

	func remove(user: UserItemData) throws {
		guard let id = user.persistenceIdentifier else {
			throw SavedUsersStoreError.missingUserIdentifier
		}

		try remove(id: id)
	}

	func remove(id: String) throws {
		let realm = try Realm()
		guard let object = realm.object(ofType: SavedUserObject.self, forPrimaryKey: id) else { return }
		try realm.write {
			realm.delete(object)
		}
	}
}
