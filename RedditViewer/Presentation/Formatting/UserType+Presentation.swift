//
//  UserType.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import Foundation

extension UserType {
	var presentationTitle: String {
		switch self {
			case .registered:
				return "Registered"
			case .moderator:
				return "Moderator"
			case .unregistered:
				return "Unregistered"
			case .teamAdmin:
				return "Team Admin"
			case .doesNotExist:
				return "Does Not Exist"
			case .unknown(let value):
				return value
		}
	}
}
