//
//  AppDependencies.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation

protocol UsersAPIClient {
	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers
	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers
}

protocol UsersRepository {
	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers
	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers
}

protocol QuestionsAPIClient {
	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse
}

protocol QuestionsRepository {
	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse
}

final class StackOverflowAPIClient: UsersAPIClient {
	private let session: URLSession

	init(session: URLSession = .shared) {
		self.session = session
	}

	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers {
		let request = try await URLRequest.usersTopReputation(page: page, pageSize: pageSize)
		return try await session.get(request: request, session: session)
	}

	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers {
		let request = try await URLRequest.usersByName(query, pageSize: pageSize)
		return try await session.get(request: request, session: session)
	}
}

final class StackOverflowQuestionsAPIClient: QuestionsAPIClient {
	private let session: URLSession

	init(session: URLSession = .shared) {
		self.session = session
	}

	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse {
		let request = try await URLRequest.questions(page: page, pageSize: pageSize)
		return try await session.get(request: request, session: session)
	}
}

final class DefaultUsersRepository: UsersRepository {
	private enum CachePolicy { //URL response local json cache - it's max age
		static let topUsersMaxAge: TimeInterval = 10 * 60
		static let searchMaxAge: TimeInterval = 5 * 60
	}

	private let apiClient: UsersAPIClient
	private let cache: UsersResponseCache

	init(apiClient: UsersAPIClient, cache: UsersResponseCache = UsersResponseCache()) {
		self.apiClient = apiClient
		self.cache = cache
	}

	func fetchTopUsers(page: Int, pageSize: Int) async throws -> StackOverflowTopUsers {
		let key = "top_users_page_\(page)_size_\(pageSize)"

		if let cached = cache.load(for: key, maxAge: CachePolicy.topUsersMaxAge) {
			return cached
		}

		let response = try await apiClient.fetchTopUsers(page: page, pageSize: pageSize)
		cache.save(response: response, for: key)
		return response
	}

	func searchUsers(query: String, pageSize: Int) async throws -> StackOverflowTopUsers {
		let normalizedQuery = query
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()
		let key = "search_\(normalizedQuery)_size_\(pageSize)"

		do {
			let response = try await apiClient.searchUsers(query: normalizedQuery, pageSize: pageSize)
			cache.save(response: response, for: key)
			return response
		} catch {
			if let cached = cache.load(for: key, maxAge: CachePolicy.searchMaxAge) {
				return cached
			}
			throw error
		}
	}
}

final class DefaultQuestionsRepository: QuestionsRepository {
	private enum CachePolicy { //URL response local json cache - it's max age
		static let questionsMaxAge: TimeInterval = 5 * 60
	}

	private let apiClient: QuestionsAPIClient
	private let cache: QuestionsResponseCache

	init(apiClient: QuestionsAPIClient, cache: QuestionsResponseCache = QuestionsResponseCache()) {
		self.apiClient = apiClient
		self.cache = cache
	}

	func fetchQuestions(page: Int, pageSize: Int) async throws -> StackOverflowQuestionsResponse {
		let key = "questions_page_\(page)_size_\(pageSize)"

		if let cached = cache.load(for: key, maxAge: CachePolicy.questionsMaxAge) {
			return cached
		}

		let response = try await apiClient.fetchQuestions(page: page, pageSize: pageSize)
		cache.save(response: response, for: key)
		return response
	}
}

final class QuestionsResponseCache {
	private struct CachedEnvelope: Codable {
		let createdAt: Date
		let response: StackOverflowQuestionsResponse
	}

	private let memoryCache = NSCache<NSString, NSData>()
	private let fileManager: FileManager
	private let cacheDirectoryURL: URL
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()

	init(fileManager: FileManager = .default) {
		self.fileManager = fileManager

		let baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
			?? fileManager.temporaryDirectory
		let directory = baseURL.appendingPathComponent("questions_response_cache", isDirectory: true)
		if !fileManager.fileExists(atPath: directory.path) {
			try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
		}
		self.cacheDirectoryURL = directory
	}

	func save(response: StackOverflowQuestionsResponse, for key: String) {
		let envelope = CachedEnvelope(createdAt: Date(), response: response)
		guard let data = try? encoder.encode(envelope) else { return }

		memoryCache.setObject(data as NSData, forKey: key as NSString)
		let url = cacheDirectoryURL.appendingPathComponent(safeFileName(for: key))
		try? data.write(to: url, options: .atomic)
	}

	func load(for key: String, maxAge: TimeInterval) -> StackOverflowQuestionsResponse? {
		if let memoryData = memoryCache.object(forKey: key as NSString) as Data?,
		   let envelope = try? decoder.decode(CachedEnvelope.self, from: memoryData),
		   abs(envelope.createdAt.timeIntervalSinceNow) <= maxAge {
			return envelope.response
		}

		let url = cacheDirectoryURL.appendingPathComponent(safeFileName(for: key))
		guard let data = try? Data(contentsOf: url),
			  let envelope = try? decoder.decode(CachedEnvelope.self, from: data),
			  abs(envelope.createdAt.timeIntervalSinceNow) <= maxAge
		else {
			return nil
		}

		memoryCache.setObject(data as NSData, forKey: key as NSString)
		return envelope.response
	}

	private func safeFileName(for key: String) -> String {
		let sanitized = key.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
		return "\(sanitized).json"
	}
}

struct AppDependencies {
	let usersRepository: UsersRepository
	let questionsRepository: QuestionsRepository
	let savedUsersStore: SavedUsersStoring

	static func live() -> AppDependencies {
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForResource = TimeInterval(5)
		configuration.waitsForConnectivity = true
		let session = URLSession(configuration: configuration)
		let apiClient = StackOverflowAPIClient(session: session)
		let questionsAPIClient = StackOverflowQuestionsAPIClient(session: session)

		return AppDependencies(
			usersRepository: DefaultUsersRepository(apiClient: apiClient),
			questionsRepository: DefaultQuestionsRepository(apiClient: questionsAPIClient),
			savedUsersStore: SavedUsersStore.shared
		)
	}
}
