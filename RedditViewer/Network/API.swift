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
private let apiKey: String = { //for read only purpose key, expires on 2026/03/24
	return "rl_GgNX8bj83QGaBGgPmbNsvrFqL"
}()

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
	static func usersTopReputation(page: Int, pageSize: Int = 30) throws -> URLRequest {
		var components = URLComponents(string: "\(domain)users")
		components?.queryItems = [
			URLQueryItem(name: "order", value: "desc"),
			URLQueryItem(name: "sort", value: "reputation"),
			URLQueryItem(name: "site", value: "stackoverflow"),
			URLQueryItem(name: "page", value: String(page)),
			URLQueryItem(name: "pagesize", value: String(pageSize)),
			URLQueryItem(name: "key", value: apiKey)
		]

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
