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
			TopUserCell.self
		]
			.forEach { tableView.registerClass($0) }
		tableView.separatorStyle = .none
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 120
		return tableView
	}()

	private let refreshControl = UIRefreshControl()
	private let paginationIndicator = UIActivityIndicatorView(style: .medium)
	private let viewModel = TopUsersViewModel()

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Top Users"
		view.backgroundColor = .systemBackground

		tableView.delegate = self
		tableView.dataSource = self
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

		paginationIndicator.hidesWhenStopped = true
		paginationIndicator.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
		tableView.tableFooterView = paginationIndicator

		viewModel.onDataDidUpdate = { [weak self] in
			self?.tableView.reloadData()
		}
		viewModel.onRefreshEnded = { [weak self] in
			self?.refreshControl.endRefreshing()
		}
		viewModel.onPaginationStateChanged = { [weak self] isLoading in
			guard let self else { return }
			if isLoading {
				self.paginationIndicator.startAnimating()
			} else {
				self.paginationIndicator.stopAnimating()
			}
			self.tableView.tableFooterView?.isHidden = !isLoading
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
		viewModel.numberOfRows()
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		viewModel.cell(for: indexPath, tableView: tableView)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
	}
}
