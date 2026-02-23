//
//  TopUsersVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 21.02.2026.
//

import UIKit
import SnapKit

class TopUsersVC: UIViewController {
	private let tableView: UITableView = {
		let tableView = UITableView()
		[
			TopUserCell.self,
			TopUserLoaderCell.self
		]
			.forEach { tableView.registerClass($0) }
		tableView.separatorStyle = .none
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 120
		return tableView
	}()

	private let refreshControl = UIRefreshControl()
	private let viewModel = TopUsersViewModel()
	private var isPaginating = false

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Top Users"
		view.backgroundColor = .systemBackground

		tableView.delegate = self
		tableView.dataSource = self
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

		viewModel.onDataDidUpdate = { [weak self] in
			self?.tableView.reloadData()
		}
		viewModel.onRefreshEnded = { [weak self] in
			self?.refreshControl.endRefreshing()
		}
		viewModel.onPaginationStateChanged = { [weak self] isLoading in
			guard let self else { return }
			guard self.isPaginating != isLoading else { return }
			self.isPaginating = isLoading

			let loaderIndexPath = IndexPath(row: self.viewModel.numberOfRows(), section: 0)
			if self.tableView.numberOfRows(inSection: 0) > loaderIndexPath.row {
				self.tableView.reloadRows(at: [loaderIndexPath], with: .none)
			} else {
				self.tableView.reloadData()
			}
		}

		setUpConstraints()
	}

	@objc private func refreshPulled() {
		viewModel.refresh()
	}

	private func setUpConstraints() {
		view.addSubview(tableView)

		tableView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}
}

extension TopUsersVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		viewModel.numberOfRows() + 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == viewModel.numberOfRows() {
			let cell = tableView.dequeueReusableCell(TopUserLoaderCell.self, for: indexPath)
			cell.setLoading(isPaginating)
			return cell
		}
		return viewModel.cell(for: indexPath, tableView: tableView)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row == viewModel.numberOfRows() {
			return 50
		}
		return UITableView.automaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row < viewModel.numberOfRows() else { return }
		guard let user = viewModel.user(at: indexPath) else { return }
		let userInfoVC = UserInfoVC(user: user)
		navigationController?.pushViewController(userInfoVC, animated: true)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard cell as? TopUserCell != nil else { return }
		viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
	}
}
