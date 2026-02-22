//
//  UIView+Extensions.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import UIKit

extension UIView {
	func addSubviews(_ views: [UIView]) {
		views.forEach { addSubview($0) }
	}
}
