//
//  PostsVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 25.02.2026.
//

import UIKit
import SnapKit

final class PostsVC: UIViewController {
	private let tableView: UITableView = {
		let tableView = UITableView()
		[
			PostCell.self,
			LoaderCell.self
		]
			.forEach { tableView.registerClass($0) }
		tableView.separatorStyle = .none
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 150
		return tableView
	}()

	private let refreshControl = UIRefreshControl()
	private let viewModel: PostsViewModel
	private let postDetailsFactory: (QuestionItemData) -> UIViewController
	private var isPaginating = false

	init(viewModel: PostsViewModel, postDetailsFactory: @escaping (QuestionItemData) -> UIViewController) {
		self.viewModel = viewModel
		self.postDetailsFactory = postDetailsFactory
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Posts"
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
		viewModel.onError = { [weak self] message in
			self?.showError(message)
		}

		setUpConstraints()
		viewModel.onViewDidLoad()
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

	private func showError(_ message: String) {
		let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
}

extension PostsVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		viewModel.numberOfRows() + 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == viewModel.numberOfRows() {
			let cell = tableView.dequeueReusableCell(LoaderCell.self, for: indexPath)
			cell.setLoading(isPaginating)
			return cell
		}

		let cell = tableView.dequeueReusableCell(PostCell.self, for: indexPath)
		if let post = viewModel.post(at: indexPath.row) {
			cell.setData(question: post)
		}
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row == viewModel.numberOfRows() {
			return 50
		}
		return UITableView.automaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row < viewModel.numberOfRows() else { return }
		guard let post = viewModel.post(at: indexPath.row) else { return }
		let detailsVC = postDetailsFactory(post)
		navigationController?.pushViewController(detailsVC, animated: true)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard cell as? PostCell != nil else { return }
		viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
	}
}
