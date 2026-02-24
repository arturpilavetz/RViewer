//
//  API.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import Foundation

enum HTTPError: Error {
	case generic
	case unuthorized
	case noCache
	case wrongResponse(String, Int, ApiError)
	case parsingError(String, Int, Error, String)
}

private let domain: String = {
	return "https://api.stackexchange.com/2.3/"
}()
private let usersEndpoint = "\(domain)users"
private let mockCredentialsURL = URL(string: "https://phxqik.mockapi.dog/")!

private enum AuthStorage {
	@KeychainWrapper("clientID.jwt") static var clientJWT: String?
	@KeychainWrapper("clientID.token") static var clientToken: String?
}

private var defaultHeaders: HTTPHeaders {
	[
		"x-client-version"  : "ios/3.0.0",
		"Accept-Language"   : Locale.current.identifier,
		"Accept-Encoding"   : "gzip;q=1.0, compress;q=0.5",
		"Accept"            : "application/json",
		"Content-Type"		: "application/json"
	]
}

public extension URLRequest {
	static func credentials() async throws -> String {
		if let cachedJWT = AuthStorage.clientJWT, !cachedJWT.isEmpty {
			return cachedJWT
		}

		do {
			let (data, response) = try await URLSession.shared.data(for: URLRequest(url: mockCredentialsURL))
			guard let httpResponse = response as? HTTPURLResponse, 200 ... 299 ~= httpResponse.statusCode else {
				throw HTTPError.unuthorized
			}

			let credentials = try decoder.decode(MockCredentialsResponse.self, from: data)
			guard let jwt = credentials.clientID, !jwt.isEmpty else {
				throw HTTPError.unuthorized
			}
			AuthStorage.clientJWT = jwt
			return jwt
		} catch {
			if let cachedJWT = AuthStorage.clientJWT {
				return cachedJWT
			}
			throw error
		}
	}

	static func usersTopReputation(page: Int, pageSize: Int = 30) async throws -> URLRequest {
		try await usersRequest(page: page, query: nil, pageSize: pageSize)
	}

	static func usersByName(_ query: String, pageSize: Int = 30) async throws -> URLRequest {
		try await usersRequest(page: nil, query: query, pageSize: pageSize)
	}

	static func apiKey() async throws -> String {
		if let cachedToken = AuthStorage.clientToken, !cachedToken.isEmpty {
			return cachedToken
		}

		if let cachedJWT = AuthStorage.clientJWT,
		   let token = cachedJWT.tokenClaimFromJWT(),
		   !token.isEmpty {
			AuthStorage.clientToken = token
			return token
		}

		let maxAttempts = 4 // attempts to get token if failed to receive/decode
		for attempt in 1 ... maxAttempts {
			try Task.checkCancellation()
			let jwt = try await URLRequest.credentials()
			if let key = jwt.tokenClaimFromJWT(), !key.isEmpty {
				AuthStorage.clientToken = key
				return key
			}

			if attempt < maxAttempts {
				AuthStorage.clientJWT = nil
				AuthStorage.clientToken = nil
				let delayMs = 250 * attempt
				try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000) // retry delay in sec
			}
		}
		throw HTTPError.unuthorized
	}

	private static func usersRequest(page: Int?, query: String?, pageSize: Int) async throws -> URLRequest {
		let apiKey = try await URLRequest.apiKey()
		var queryItems = [
			URLQueryItem(name: "order", value: "desc"),
			URLQueryItem(name: "sort", value: "reputation"),
			URLQueryItem(name: "pagesize", value: String(pageSize)),
			URLQueryItem(name: "site", value: "stackoverflow"),
			URLQueryItem(name: "key", value: apiKey)
		]
		if let page {
			queryItems.append(URLQueryItem(name: "page", value: String(page)))
		}
		if let query, !query.isEmpty {
			queryItems.append(URLQueryItem(name: "inname", value: query))
		}

		var components = URLComponents(string: usersEndpoint)
		components?.queryItems = queryItems

		guard let url = components?.url else {
			throw HTTPError.generic
		}

		return URLRequest(url: url)
	}
}

private var decoder: JSONDecoder {
	get {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(dateFormatter)
		return decoder
	}
}

extension URLSession {
	func get<Response: Codable>(request: URLRequest, session: URLSession = .shared) async throws -> Response {
		var request = request
		request.httpMethod = "GET"

		for (headerField, value) in defaultHeaders {
			request.addValue(value, forHTTPHeaderField: headerField)
		}

		let (data, response) = try await session.data(for: request)

		if let httpResponse = response as? HTTPURLResponse,
		   200 ... 299 ~= httpResponse.statusCode {
			do {
				let decoded = try decoder.decode(Response.self, from: data)
				return decoded
			} catch {
				throw HTTPError.parsingError(request.url?.absoluteString ?? "", httpResponse.statusCode, error, String(data: data, encoding: .utf8) ?? "")
			}
		}

		let apiError = try decoder.decode(ApiError.self, from: data)
		throw HTTPError.wrongResponse(request.url?.absoluteString ?? "", (response as? HTTPURLResponse)?.statusCode ?? 0, apiError)
	}
}

private extension String {
	func tokenClaimFromJWT() -> String? {
		let segments = self.split(separator: ".")
		guard segments.count == 3 else { return nil }

		var base64 = String(segments[1])
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
		let padding = 4 - (base64.count % 4)
		if padding < 4 {
			base64 += String(repeating: "=", count: padding)
		}

		guard
			let payloadData = Data(base64Encoded: base64),
			let payload = try? JSONDecoder().decode([String: String].self, from: payloadData)
		else {
			return nil
		}
		return payload["token"]
	}
}
