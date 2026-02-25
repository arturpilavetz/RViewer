//
//  TabVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import UIKit

final class TabVC: UITabBarController, UITabBarControllerDelegate {
	private let dependencies: AppDependencies

	init(dependencies: AppDependencies) {
		self.dependencies = dependencies
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		setUpChildren()
		setupImageAndTitle()

		delegate = self
	}

	private func setUpChildren() {
		let makeUserDetails: (UserItemData) -> UIViewController = { [dependencies] user in
			UserInfoVC(user: user, savedUsersStore: dependencies.savedUsersStore)
		}
		let makePostDetails: (QuestionItemData) -> UIViewController = { post in
			PostDetailsVC(question: post, userDetailsFactory: makeUserDetails)
		}

		let topUsersViewModel = TopUsersViewModel(repository: dependencies.usersRepository)
		let topUsersVC = TopUsersVC(viewModel: topUsersViewModel, userDetailsFactory: makeUserDetails)
		let topUsersNav = UINavigationController(rootViewController: topUsersVC)

		let postsViewModel = PostsViewModel(repository: dependencies.questionsRepository)
		let postsVC = PostsVC(viewModel: postsViewModel, postDetailsFactory: makePostDetails)
		let postsNav = UINavigationController(rootViewController: postsVC)

		let searchViewModel = SearchViewModel(repository: dependencies.usersRepository)
		let searchVC = SearchVC(viewModel: searchViewModel, userDetailsFactory: makeUserDetails)
		let searchNav = UINavigationController(rootViewController: searchVC)

		let savedUsersViewModel = SavedUsersViewModel(store: dependencies.savedUsersStore)
		let savedVC = SavedUsersVC(viewModel: savedUsersViewModel, userDetailsFactory: makeUserDetails)
		let savedNav = UINavigationController(rootViewController: savedVC)

		setViewControllers([topUsersNav, postsNav, searchNav, savedNav], animated: true)
	}

	private func setupImageAndTitle() {
		guard let items = tabBar.items, items.count >= 4 else { return }

		items[0].title = "Top Users"
		items[1].title = "Posts"
		items[2].title = "Search"
		items[3].title = "Saved"

		items[0].image = UIImage(systemName: "person.3")
		items[0].selectedImage = UIImage(systemName: "person.3.fill")

		items[1].image = UIImage(systemName: "doc.text")
		items[1].selectedImage = UIImage(systemName: "doc.text.fill")

		items[2].image = UIImage(systemName: "magnifyingglass")
		items[2].selectedImage = UIImage(systemName: "magnifyingglass")

		items[3].image = UIImage(systemName: "star")
		items[3].selectedImage = UIImage(systemName: "star.fill")
	}
}
