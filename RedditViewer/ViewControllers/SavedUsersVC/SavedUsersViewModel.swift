//
//  SavedUsersViewModel.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation

final class SavedUsersViewModel {
	private var users: [UserItemData] = []
	private let store: SavedUsersStoring

	var onDataDidUpdate: (() -> Void)?

	init(store: SavedUsersStoring) {
		self.store = store
	}

	func reloadUsers() {
		users = store.fetchUsers()
		onDataDidUpdate?()
	}

	func numberOfRows() -> Int {
		users.count
	}

	func user(at index: Int) -> UserItemData? {
		guard index >= 0, index < users.count else { return nil }
		return users[index]
	}

	@discardableResult
	func remove(at index: Int) -> Bool {
		guard let user = user(at: index) else { return false }

		do {
			try store.remove(user: user)
			users.remove(at: index)
			onDataDidUpdate?()
			return true
		} catch {
			return false
		}
	}
}
