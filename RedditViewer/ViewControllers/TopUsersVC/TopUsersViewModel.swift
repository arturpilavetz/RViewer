//
//  TopUsersViewModel.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 22.02.2026.
//

import UIKit

final class TopUsersViewModel {
	private var topUsers: [UserItemData] = []
	private var currentPage = 1
	private var hasMore = true
	private var isLoading = false

	private let nextPageTriggerOffset = 6
	private let pageSize = 30

	var onDataDidUpdate: (() -> Void)?
	var onRefreshEnded: (() -> Void)?
	var onPaginationStateChanged: ((Bool) -> Void)?

	init() {
		getTopUsers(reset: true)
	}

	deinit {
		print("TopUsersViewModel deinitialized")
	}

	func cell(for indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(TopUserCell.self, for: indexPath)
		cell.setData(user: topUsers[indexPath.row])
		return cell
	}

	func numberOfRows() -> Int {
		topUsers.count
	}

	func user(at indexPath: IndexPath) -> UserItemData? {
		guard indexPath.row >= 0, indexPath.row < topUsers.count else { return nil }
		return topUsers[indexPath.row]
	}

	func refresh() {
		getTopUsers(reset: true)
	}

	func loadNextPageIfNeeded(currentIndex: Int) {
		guard currentIndex >= topUsers.count - nextPageTriggerOffset else { return }
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
				let configuration = URLSessionConfiguration.default
				configuration.timeoutIntervalForResource = TimeInterval(5)
				configuration.waitsForConnectivity = true
				let session = URLSession(configuration: configuration)

				let page = reset ? 1 : currentPage
				let request = try URLRequest.usersTopReputation(page: page, pageSize: pageSize)
				let response: StackOverflowTopUsers = try await session.get(request: request, session: session)
				let loadedUsers = response.users ?? []

				await MainActor.run {
					if reset {
						topUsers = loadedUsers
						currentPage = 2
					} else {
						topUsers.append(contentsOf: loadedUsers)
						currentPage += 1
					}

					hasMore = response.hasMore ?? false
					isLoading = false

					print("*** \(response.quotaRemaining ?? 0)")
					onPaginationStateChanged?(false)
					onDataDidUpdate?()
					onRefreshEnded?()
				}
			} catch {
				await MainActor.run {
					isLoading = false
					onRefreshEnded?()
					onPaginationStateChanged?(false)
				}
				print(error)
			}
		}
	}
}
