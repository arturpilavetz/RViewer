//
//  ApiError.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import Foundation

struct ApiError: Codable {
	var error: Bool?
	var errorCode: Int?
	var code: Int?
	var description: String?

	enum CodingKeys: String, CodingKey {
		case error
		case errorCode = "error_code"
		case description
		case code
	}
}
