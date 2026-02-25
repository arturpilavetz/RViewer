//
//  TopUsersViewModel.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 22.02.2026.
//

import Foundation

final class TopUsersViewModel {
	private var users: [UserItemData] = []
	private var currentPage = 1
	private var hasMore = true
	private var isLoading = false

	private let nextPageTriggerOffset = 6
	private let pageSize = 30
	private let repository: UsersRepository

	var onDataDidUpdate: (() -> Void)?
	var onRefreshEnded: (() -> Void)?
	var onPaginationStateChanged: ((Bool) -> Void)?
	var onError: ((String) -> Void)?

	init(repository: UsersRepository) {
		self.repository = repository
	}

	func onViewDidLoad() {
		getTopUsers(reset: true)
	}

	func numberOfRows() -> Int {
		users.count
	}

	func user(at index: Int) -> UserItemData? {
		guard index >= 0, index < users.count else { return nil }
		return users[index]
	}

	func refresh() {
		getTopUsers(reset: true)
	}

	func loadNextPageIfNeeded(currentIndex: Int) {
		guard currentIndex >= users.count - nextPageTriggerOffset else { return }
		getTopUsers(reset: false)
	}

	private func getTopUsers(reset: Bool) {
		guard !isLoading else { return }
		guard reset || hasMore else { return }

		isLoading = true
		if !reset {
			onPaginationStateChanged?(true)
		}

		Task {
			do {
				let page = reset ? 1 : currentPage
				let response = try await repository.fetchTopUsers(page: page, pageSize: pageSize)
				let loadedUsers = response.users ?? []

				await MainActor.run {
					if reset {
						users = loadedUsers
						currentPage = 2
					} else {
						users.append(contentsOf: loadedUsers)
						currentPage += 1
					}

					hasMore = response.hasMore ?? false
					isLoading = false

					onPaginationStateChanged?(false)
					onDataDidUpdate?()
					onRefreshEnded?()
				}
			} catch {
				await MainActor.run {
					isLoading = false
					onRefreshEnded?()
					onPaginationStateChanged?(false)
					onError?("Failed to load users")
				}
			}
		}
	}
}
