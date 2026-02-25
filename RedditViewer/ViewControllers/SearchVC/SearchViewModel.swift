//
//  SearchViewModel.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation

final class SearchViewModel {
	private var users: [UserItemData] = []
	private var searchTask: Task<Void, Never>?
	private let repository: UsersRepository

	private(set) var hasQuery = false

	var onDataDidUpdate: (() -> Void)?
	var onError: ((String) -> Void)?

	init(repository: UsersRepository) {
		self.repository = repository
	}

	func numberOfRows() -> Int {
		users.count
	}

	func user(at index: Int) -> UserItemData? {
		guard index >= 0, index < users.count else { return nil }
		return users[index]
	}

	func search(query: String) {
		searchTask?.cancel()
		hasQuery = !query.isEmpty

		searchTask = Task { [weak self] in
			guard let self else { return }
			do {
				let response = try await repository.searchUsers(query: query, pageSize: 30)
				let items = response.users ?? []

				await MainActor.run {
					self.users = items
					self.onDataDidUpdate?()
				}
			} catch is CancellationError {
				return
			} catch {
				await MainActor.run {
					self.users.removeAll()
					self.onDataDidUpdate?()
					self.onError?("Failed to load users")
				}
			}
		}
	}

	func cancelSearch() {
		searchTask?.cancel()
		hasQuery = false
		users.removeAll()
		onDataDidUpdate?()
	}
}
