//
//  TabVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import UIKit

final class TabVC: UITabBarController, UITabBarControllerDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()

		setUpChildren()
		setupImageAndTitle()

		delegate = self
	}

	private func setUpChildren() {
		let topUsersNav = UINavigationController(rootViewController: TopUsersVC())
		let searchNav = UINavigationController(rootViewController: SearchVC())
		let savedNav = UINavigationController(rootViewController: SavedUsersVC())

		setViewControllers([topUsersNav, searchNav, savedNav], animated: true)
	}

	private func setupImageAndTitle() {
		guard let items = tabBar.items, items.count >= 3 else { return }


		items[0].title = "Top Users"
		items[1].title = "Search"
		items[2].title = "Saved"

		items[0].image = UIImage(systemName: "person.3")
		items[0].selectedImage = UIImage(systemName: "person.3.fill")

		items[1].image = UIImage(systemName: "magnifyingglass")
		items[1].selectedImage = UIImage(systemName: "magnifyingglass")

		items[2].image = UIImage(systemName: "star")
		items[2].selectedImage = UIImage(systemName: "star.fill")
	}
}
