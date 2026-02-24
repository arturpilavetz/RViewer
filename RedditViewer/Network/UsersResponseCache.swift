//
//  UsersResponseCache.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation

final class UsersResponseCache {
	private struct CachedEnvelope: Codable {
		let createdAt: Date
		let response: StackOverflowTopUsers
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
		let directory = baseURL.appendingPathComponent("users_response_cache", isDirectory: true)
		if !fileManager.fileExists(atPath: directory.path) {
			try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
		}
		self.cacheDirectoryURL = directory
	}

	func save(response: StackOverflowTopUsers, for key: String) {
		let envelope = CachedEnvelope(createdAt: Date(), response: response)
		guard let data = try? encoder.encode(envelope) else { return }

		memoryCache.setObject(data as NSData, forKey: key as NSString)
		let url = cacheDirectoryURL.appendingPathComponent(safeFileName(for: key))
		try? data.write(to: url, options: .atomic)
	}

	func load(for key: String, maxAge: TimeInterval) -> StackOverflowTopUsers? {
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
