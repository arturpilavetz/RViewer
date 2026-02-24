//
//  SavedUsersVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import UIKit
import SnapKit

final class SavedUsersVC: UIViewController {
	private let tableView: UITableView = {
		let tableView = UITableView()
		tableView.registerClass(UserCell.self)
		tableView.separatorStyle = .none
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 120
		return tableView
	}()

	private let emptyStateLabel: UILabel = {
		let label = UILabel()
		label.text = "No saved users yet"
		label.textColor = .secondaryLabel
		label.font = .systemFont(ofSize: 15, weight: .medium)
		label.textAlignment = .center
		label.numberOfLines = 0
		return label
	}()

	private let viewModel: SavedUsersViewModel
	private let userDetailsFactory: (UserItemData) -> UIViewController

	init(viewModel: SavedUsersViewModel, userDetailsFactory: @escaping (UserItemData) -> UIViewController) {
		self.viewModel = viewModel
		self.userDetailsFactory = userDetailsFactory
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Saved"
		view.backgroundColor = .systemBackground

		tableView.dataSource = self
		tableView.delegate = self

		viewModel.onDataDidUpdate = { [weak self] in
			guard let self else { return }
			self.tableView.reloadData()
			self.emptyStateLabel.isHidden = self.viewModel.numberOfRows() > 0
		}

		setUpConstraints()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.reloadUsers()
	}

	private func setUpConstraints() {
		view.addSubviews([tableView, emptyStateLabel])

		tableView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

		emptyStateLabel.snp.makeConstraints { make in
			make.center.equalToSuperview()
			make.leading.trailing.equalToSuperview().inset(24)
		}
	}
}

extension SavedUsersVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		viewModel.numberOfRows()
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(UserCell.self, for: indexPath)
		if let user = viewModel.user(at: indexPath.row) {
			cell.setData(user: user)
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let user = viewModel.user(at: indexPath.row) else { return }
		let userInfoVC = userDetailsFactory(user)
		navigationController?.pushViewController(userInfoVC, animated: true)
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
			guard let self else {
				completion(false)
				return
			}

			completion(self.viewModel.remove(at: indexPath.row))
		}
		deleteAction.backgroundColor = .systemRed

		let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
		configuration.performsFirstActionWithFullSwipe = true
		return configuration
	}
}
