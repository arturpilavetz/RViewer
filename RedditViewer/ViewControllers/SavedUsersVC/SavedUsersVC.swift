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
		tableView.registerClass(TopUserCell.self)
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

	private var users: [UserItemData] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Saved"
		view.backgroundColor = .systemBackground

		tableView.dataSource = self
		tableView.delegate = self

		setUpConstraints()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		reloadUsers()
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

	private func reloadUsers() {
		users = SavedUsersStore.shared.fetchUsers()
		tableView.reloadData()
		emptyStateLabel.isHidden = !users.isEmpty
	}
}

extension SavedUsersVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		users.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(TopUserCell.self, for: indexPath)
		cell.setData(user: users[indexPath.row])
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row >= 0, indexPath.row < users.count else { return }
		let userInfoVC = UserInfoVC(user: users[indexPath.row])
		navigationController?.pushViewController(userInfoVC, animated: true)
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
			guard let self else {
				completion(false)
				return
			}
			guard indexPath.row >= 0, indexPath.row < self.users.count else {
				completion(false)
				return
			}

			let user = self.users[indexPath.row]
			do {
				try SavedUsersStore.shared.remove(user: user)
				self.users.remove(at: indexPath.row)
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
				self.emptyStateLabel.isHidden = !self.users.isEmpty
				completion(true)
			} catch {
				completion(false)
			}
		}
		deleteAction.backgroundColor = .systemRed

		let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
		configuration.performsFirstActionWithFullSwipe = true
		return configuration
	}
}
