//
//  AvatarImageLoader.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import UIKit

final class AvatarImageLoader {
	static let shared = AvatarImageLoader()
	private let cache = NSCache<NSString, UIImage>()

	private init() {}

	func image(for urlString: String?) async -> UIImage? {
		guard let urlString,
			  let url = URL(string: urlString) else { return nil }

		if let cached = cache.object(forKey: urlString as NSString) {
			return cached
		}

		do {
			let (data, _) = try await URLSession.shared.data(from: url)
			guard let image = UIImage(data: data) else { return nil }
			cache.setObject(image, forKey: urlString as NSString)
			return image
		} catch {
			return nil
		}
	}
}
