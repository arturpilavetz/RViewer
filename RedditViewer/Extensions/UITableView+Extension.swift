//
//  UITableView+Extension.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 22.02.2026.
//

import UIKit

extension UITableView {
	func dequeue<T: UITableViewCell>(_ withClass: T.Type, for indexPath: IndexPath) -> CellContainer<T> {
		return CellContainer({ [weak self] in
			self?.dequeueReusableCell(withIdentifier: String(describing: withClass), for: indexPath) as? T
		})
	}

	func dequeueReusableCell<T: UITableViewCell>(_ withClass: T.Type, for indexPath: IndexPath) -> T {
		return dequeueReusableCell(withIdentifier: String(describing: withClass), for: indexPath) as! T
	}

	func registerClass<T: UITableViewCell>(_ cellClass: T.Type) {
		register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
	}
}

struct CellContainer<T: UITableViewCell> {
	private var constructor: () -> T?

	init(_ constructor: @escaping () -> T?) {
		self.constructor = constructor
	}

	func configure(_ closure: (T) -> ()) -> UITableViewCell {
		switch constructor() {
			case .some(let unwrapped):
				closure(unwrapped)
				return unwrapped
			case .none:
				return UITableViewCell()
		}
	}
}
