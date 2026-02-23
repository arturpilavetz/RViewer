//
//  UserInfoRowView.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import UIKit

final class UserInfoRowView: UIView {
	let copyValue: String

	init(copyValue: String) {
		self.copyValue = copyValue
		super.init(frame: .zero)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
