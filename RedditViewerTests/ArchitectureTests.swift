//
//  ArchitectureTests.swift
//  RedditViewerTests
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import Foundation
import Testing
@testable import RedditViewer

@MainActor
struct ArchitectureTests {
	@Test
	func usersRepositoryReturnsCachedTopUsersBeforeNetwork() async throws {
		clearCacheDirectory(named: "users_response_cache")
		let cache = UsersResponseCache()
		let cached = makeUsersResponse(count: 2, hasMore: false)
		cache.save(response: cached, for: "top_users_page_1_size_30")

		let api = UsersAPIClientMock(
			topUsersHandler: { _, _ in throw MockError.failed },
			searchHandler: { _, _ in throw MockError.failed }
		)
		let repository = DefaultUsersRepository(apiClient: api, cache: cache)

		let result = try await repository.fetchTopUsers(page: 1, pageSize: 30)
		#expect(result.users?.count == 2)
		#expect(await api.fetchTopUsersCallCount() == 0)
	}

	@Test
	func usersRepositoryCachesSearchFallbackOnFailure() async throws {
		clearCacheDirectory(named: "users_response_cache")
		let cache = UsersResponseCache()
		let cached = makeUsersResponse(count: 1, hasMore: false)
		cache.save(response: cached, for: "search_john_size_30")

		let api = UsersAPIClientMock(
			topUsersHandler: { _, _ in makeUsersResponse(count: 0, hasMore: false) },
			searchHandler: { _, _ in throw MockError.failed }
		)
		let repository = DefaultUsersRepository(apiClient: api, cache: cache)

		let result = try await repository.searchUsers(query: "john", pageSize: 30)
		#expect(result.users?.count == 1)
		#expect(await api.searchUsersCallCount() == 1)
	}

	@Test
	func questionsRepositoryReturnsCachedDataBeforeNetwork() async throws {
		clearCacheDirectory(named: "questions_response_cache")
		let cache = QuestionsResponseCache()
		let cached = makeQuestionsResponse(count: 3, hasMore: false)
		cache.save(response: cached, for: "questions_page_1_size_30")

		let api = QuestionsAPIClientMock(fetchHandler: { _, _ in throw MockError.failed })
		let repository = DefaultQuestionsRepository(apiClient: api, cache: cache)

		let result = try await repository.fetchQuestions(page: 1, pageSize: 30)
		#expect(result.questions?.count == 3)
		#expect(await api.fetchQuestionsCallCount() == 0)
	}

	@Test
	func topUsersViewModelLoadsInitialData() async throws {
		let repository = UsersRepositoryMock(
			topUsersHandler: { _, _ in makeUsersResponse(count: 4, hasMore: false) },
			searchHandler: { _, _ in makeUsersResponse(count: 0, hasMore: false) }
		)
		let viewModel = TopUsersViewModel(repository: repository)

		let state = CallbackState()
		viewModel.onDataDidUpdate = {
			Task {
				await state.markUpdated()
			}
		}

		viewModel.onViewDidLoad()
		let didUpdate = await waitUntil {
			await state.isUpdated
		}

		#expect(didUpdate)
		#expect(viewModel.numberOfRows() == 4)
	}

	@Test
	func topUsersViewModelPaginates() async throws {
		let repository = UsersRepositoryMock(
			topUsersHandler: { page, _ in
				if page == 1 { return makeUsersResponse(count: 10, hasMore: true) }
				return makeUsersResponse(count: 10, hasMore: false)
			},
			searchHandler: { _, _ in makeUsersResponse(count: 0, hasMore: false) }
		)
		let viewModel = TopUsersViewModel(repository: repository)

		viewModel.onViewDidLoad()
		_ = await waitUntil { viewModel.numberOfRows() == 10 }
		viewModel.loadNextPageIfNeeded(currentIndex: 9)
		_ = await waitUntil { viewModel.numberOfRows() == 20 }

		#expect(viewModel.numberOfRows() == 20)
	}

	@Test
	func postsViewModelLoadsData() async throws {
		let repository = QuestionsRepositoryMock(fetchHandler: { _, _ in makeQuestionsResponse(count: 5, hasMore: false) })
		let viewModel = PostsViewModel(repository: repository)

		viewModel.onViewDidLoad()
		let loaded = await waitUntil { viewModel.numberOfRows() == 5 }

		#expect(loaded)
	}

	@Test
	func searchViewModelCancelClearsState() async throws {
		let repository = UsersRepositoryMock(
			topUsersHandler: { _, _ in makeUsersResponse(count: 0, hasMore: false) },
			searchHandler: { _, _ in
				try await Task.sleep(nanoseconds: 150_000_000)
				return makeUsersResponse(count: 2, hasMore: false)
			}
		)
		let viewModel = SearchViewModel(repository: repository)

		viewModel.search(query: "john")
		viewModel.cancelSearch()

		#expect(viewModel.hasQuery == false)
		#expect(viewModel.numberOfRows() == 0)
	}

	@Test
	func usersResponseCacheSaveAndLoad() async throws {
		clearCacheDirectory(named: "users_response_cache")
		let cache = UsersResponseCache()
		let response = makeUsersResponse(count: 1, hasMore: false)
		cache.save(response: response, for: "any_key")

		let loaded = cache.load(for: "any_key", maxAge: 60)
		#expect(loaded?.users?.count == 1)

		let expired = cache.load(for: "any_key", maxAge: -1)
		#expect(expired == nil)
	}

	@Test
	func questionsResponseCacheSaveAndLoad() async throws {
		clearCacheDirectory(named: "questions_response_cache")
		let cache = QuestionsResponseCache()
		let response = makeQuestionsResponse(count: 1, hasMore: false)
		cache.save(response: response, for: "any_key")

		let loaded = cache.load(for: "any_key", maxAge: 60)
		#expect(loaded?.questions?.count == 1)

		let expired = cache.load(for: "any_key", maxAge: -1)
		#expect(expired == nil)
	}
}

private enum MockError: Error {
	case failed
}

private actor CallbackState {
	private(set) var isUpdated = false

	func markUpdated() {
		isUpdated = true
	}
}

private actor CallCounter {
	private var value = 0

	func increment() {
		value += 1
	}

	func current() -> Int {
		value
	}
}

private final class UsersAPIClientMock: UsersAPIClient {
	private let topUsersHandler: @Sendable (Int, Int) async throws -> StackOverflowTopUsers
	private let searchHandler: @Sendable (String, Int) async throws -> StackOverflowTopUsers

	private let topUsersCounter = CallCounter()
	private let searchUsersCounter = CallCounter()

	init(
		topUsersHandler: @escaping @Sendable (Int, Int) async throws -> StackOverflowTopUsers,
		searchHandler: @escaping @Sendable (String, Int) async throws -> StackOverflowTopUsers
	) {
		self.topUsersHandler = topUsersHandler
		self.searchHandler = searchHandler
	}

	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers {
		await topUsersCounter.increment()
		return try await topUsersHandler(page, pageSize)
	}

	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers {
		await searchUsersCounter.increment()
		return try await searchHandler(query, pageSize)
	}

	func fetchTopUsersCallCount() async -> Int {
		await topUsersCounter.current()
	}

	func searchUsersCallCount() async -> Int {
		await searchUsersCounter.current()
	}
}

private final class QuestionsAPIClientMock: QuestionsAPIClient {
	private let fetchHandler: @Sendable (Int, Int) async throws -> StackOverflowQuestionsResponse
	private let fetchQuestionsCounter = CallCounter()

	init(fetchHandler: @escaping @Sendable (Int, Int) async throws -> StackOverflowQuestionsResponse) {
		self.fetchHandler = fetchHandler
	}

	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse {
		await fetchQuestionsCounter.increment()
		return try await fetchHandler(page, pageSize)
	}

	func fetchQuestionsCallCount() async -> Int {
		await fetchQuestionsCounter.current()
	}
}

private final class UsersRepositoryMock: UsersRepository {
	private let topUsersHandler: @Sendable (Int, Int) async throws -> StackOverflowTopUsers
	private let searchHandler: @Sendable (String, Int) async throws -> StackOverflowTopUsers

	init(
		topUsersHandler: @escaping @Sendable (Int, Int) async throws -> StackOverflowTopUsers,
		searchHandler: @escaping @Sendable (String, Int) async throws -> StackOverflowTopUsers
	) {
		self.topUsersHandler = topUsersHandler
		self.searchHandler = searchHandler
	}

	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers {
		try await topUsersHandler(page, pageSize)
	}

	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers {
		try await searchHandler(query, pageSize)
	}
}

private final class QuestionsRepositoryMock: QuestionsRepository {
	private let fetchHandler: @Sendable (Int, Int) async throws -> StackOverflowQuestionsResponse

	init(fetchHandler: @escaping @Sendable (Int, Int) async throws -> StackOverflowQuestionsResponse) {
		self.fetchHandler = fetchHandler
	}

	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse {
		try await fetchHandler(page, pageSize)
	}
}

private func makeUsersResponse(count: Int, hasMore: Bool) -> StackOverflowTopUsers {
	let users = (0 ..< count).map {
		UserItemData(
			badgeCounts: nil,
			collectives: nil,
			accountID: 1_000 + $0,
			isEmployee: nil,
			lastModifiedDate: nil,
			lastAccessDate: nil,
			reputationChangeYear: nil,
			reputationChangeQuarter: nil,
			reputationChangeMonth: nil,
			reputationChangeWeek: nil,
			reputationChangeDay: nil,
			reputation: 10 + $0,
			creationDate: nil,
			userType: .registered,
			userID: 2_000 + $0,
			acceptRate: nil,
			location: nil,
			websiteURL: nil,
			link: "https://example.com/\($0)",
			profileImage: nil,
			displayName: "User \($0)"
		)
	}

	return StackOverflowTopUsers(users: users, hasMore: hasMore, quotaMax: 10_000, quotaRemaining: 9_000)
}

private func makeQuestionsResponse(count: Int, hasMore: Bool) -> StackOverflowQuestionsResponse {
	let questions = (0 ..< count).map {
		QuestionItemData(
			tags: ["swift", "ios"],
			owner: QuestionOwnerData(
				accountID: 100 + $0,
				reputation: 1_000,
				userID: 200 + $0,
				userType: "registered",
				profileImage: nil,
				displayName: "Author \($0)",
				link: "https://stackoverflow.com/users/\(200 + $0)"
			),
			isAnswered: false,
			viewCount: 100,
			answerCount: 2,
			score: 10,
			creationDate: 1_700_000_000,
			questionID: 300 + $0,
			link: "https://stackoverflow.com/questions/\(300 + $0)",
			title: "Question \($0)",
			body: "<p>Body \($0)</p>"
		)
	}

	return StackOverflowQuestionsResponse(questions: questions, hasMore: hasMore, quotaMax: 10_000, quotaRemaining: 9_000)
}

@MainActor
private func waitUntil(timeoutMillis: UInt64 = 2_000, condition: @escaping () async -> Bool) async -> Bool {
	let step: UInt64 = 50
	let iterations = timeoutMillis / step
	for _ in 0 ..< iterations {
		if await condition() { return true }
		try? await Task.sleep(nanoseconds: step * 1_000_000)
	}
	return await condition()
}

private func clearCacheDirectory(named directoryName: String) {
	let fileManager = FileManager.default
	let baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		?? fileManager.temporaryDirectory
	let directory = baseURL.appendingPathComponent(directoryName, isDirectory: true)
	if fileManager.fileExists(atPath: directory.path) {
		try? fileManager.removeItem(at: directory)
	}
	try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
}
