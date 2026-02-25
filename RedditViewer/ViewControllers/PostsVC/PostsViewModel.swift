//
//  PostsViewModel.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 25.02.2026.
//

import Foundation

final class PostsViewModel {
	private var posts: [QuestionItemData] = []
	private var currentPage = 1
	private var hasMore = true
	private var isLoading = false

	private let nextPageTriggerOffset = 6
	private let pageSize = 30
	private let repository: QuestionsRepository

	var onDataDidUpdate: (() -> Void)?
	var onRefreshEnded: (() -> Void)?
	var onPaginationStateChanged: ((Bool) -> Void)?
	var onError: ((String) -> Void)?

	init(repository: QuestionsRepository) {
		self.repository = repository
	}

	func onViewDidLoad() {
		getPosts(reset: true)
	}

	func numberOfRows() -> Int {
		posts.count
	}

	func post(at index: Int) -> QuestionItemData? {
		guard index >= 0, index < posts.count else { return nil }
		return posts[index]
	}

	func refresh() {
		getPosts(reset: true)
	}

	func loadNextPageIfNeeded(currentIndex: Int) {
		guard currentIndex >= posts.count - nextPageTriggerOffset else { return }
		getPosts(reset: false)
	}

	private func getPosts(reset: Bool) {
		guard !isLoading else { return }
		guard reset || hasMore else { return }

		isLoading = true
		if !reset {
			onPaginationStateChanged?(true)
		}

		Task {
			do {
				let page = reset ? 1 : currentPage
				let response = try await repository.fetchQuestions(page: page, pageSize: pageSize)
				let loadedPosts = response.questions ?? []

				await MainActor.run {
					if reset {
						posts = loadedPosts
						currentPage = 2
					} else {
						posts.append(contentsOf: loadedPosts)
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
					onError?("Failed to load posts")
				}
			}
		}
	}
}
