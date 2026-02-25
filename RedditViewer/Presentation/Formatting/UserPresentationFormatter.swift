//
//  UserPresentationFormatter.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import UIKit

enum UserPresentationFormatter {
	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		return formatter
	}()

	static func compactCount(_ value: Int) -> String {
		if value >= 1_000_000 {
			return String(format: "%.1fm", Double(value) / 1_000_000.0)
		}
		if value >= 1_000 {
			return String(format: "%.1fk", Double(value) / 1_000.0)
		}
		return "\(value)"
	}

	static func unixDate(_ value: Int?) -> String {
		guard let value else { return "-" }
		let date = Date(timeIntervalSince1970: TimeInterval(value))
		return dateFormatter.string(from: date)
	}

	static func badgesText(_ badges: BadgeCounts?) -> NSAttributedString {
		let text = NSMutableAttributedString()
		text.append(NSAttributedString(string: "● \(badges?.gold ?? 0)  ", attributes: [.foregroundColor: UIColor.systemYellow]))
		text.append(NSAttributedString(string: "● \(badges?.silver ?? 0)  ", attributes: [.foregroundColor: UIColor.systemGray]))
		text.append(NSAttributedString(string: "● \(badges?.bronze ?? 0)", attributes: [.foregroundColor: UIColor.systemBrown]))
		return text
	}
}
