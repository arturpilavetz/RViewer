//
//  SearchVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import UIKit
import SnapKit

final class SearchVC: UIViewController {
	private let searchBar: UISearchBar = {
		let bar = UISearchBar()
		bar.placeholder = "Search by username"
		bar.returnKeyType = .search
		return bar
	}()

	private let tableView: UITableView = {
		let tableView = UITableView()
		tableView.registerClass(UserCell.self)
		tableView.separatorStyle = .none
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 120
		tableView.keyboardDismissMode = .onDrag
		return tableView
	}()

	private let emptyStateLabel: UILabel = {
		let label = UILabel()
		label.text = "Start typing to find users"
		label.textColor = .secondaryLabel
		label.font = .systemFont(ofSize: 15, weight: .medium)
		label.textAlignment = .center
		label.numberOfLines = 0
		return label
	}()

	private let viewModel: SearchViewModel
	private let userDetailsFactory: (UserItemData) -> UIViewController

	private var debounceTimer: Timer?
	private var searchBarBottomConstraint: Constraint?

	private let minQueryLength = 2

	init(viewModel: SearchViewModel, userDetailsFactory: @escaping (UserItemData) -> UIViewController) {
		self.viewModel = viewModel
		self.userDetailsFactory = userDetailsFactory
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Search"
		view.backgroundColor = .systemBackground

		searchBar.delegate = self
		tableView.dataSource = self
		tableView.delegate = self

		viewModel.onDataDidUpdate = { [weak self] in
			self?.tableView.reloadData()
			self?.updateEmptyState()
		}
		viewModel.onError = { [weak self] message in
			self?.showError(message)
		}

		setUpConstraints()
		observeKeyboard()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		debounceTimer?.invalidate()
		viewModel.cancelSearch()
	}

	private func setUpConstraints() {
		view.addSubviews([
			tableView,
			searchBar,
			emptyStateLabel
		])

		tableView.snp.makeConstraints { make in
			make.top.leading.trailing.equalToSuperview()
			make.bottom.equalTo(searchBar.snp.top)
		}

		searchBar.snp.makeConstraints { make in
			make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
			searchBarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
		}

		emptyStateLabel.snp.makeConstraints { make in
			make.center.equalTo(tableView)
			make.leading.trailing.equalToSuperview().inset(24)
		}
	}

	private func observeKeyboard() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleKeyboardNotification(_:)),
			name: UIResponder.keyboardWillChangeFrameNotification,
			object: nil
		)
	}

	@objc private func handleKeyboardNotification(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
			  let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
			  let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
			return
		}

		let endFrame = view.convert(endFrameValue.cgRectValue, from: nil)
		let keyboardOverlap = max(0, view.bounds.maxY - endFrame.minY)
		let safeAreaBottomInset = view.safeAreaInsets.bottom
		let bottomOffset = -(max(0, keyboardOverlap - safeAreaBottomInset))
		searchBarBottomConstraint?.update(offset: bottomOffset)

		let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
		UIView.animate(withDuration: duration, delay: 0, options: options) {
			self.view.layoutIfNeeded()
		}
	}

	private func performSearch(query rawQuery: String) {
		let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)

		guard query.count >= minQueryLength else {
			viewModel.cancelSearch()
			tableView.reloadData()
			emptyStateLabel.text = "Type at least \(minQueryLength) letters"
			emptyStateLabel.isHidden = false
			searchBar.setShowsCancelButton(false, animated: true)
			return
		}

		searchBar.setShowsCancelButton(true, animated: true)
		emptyStateLabel.text = "Searching..."
		emptyStateLabel.isHidden = false
		viewModel.search(query: query)
	}

	private func updateEmptyState() {
		if viewModel.numberOfRows() == 0 {
			emptyStateLabel.text = viewModel.hasQuery ? "No users found" : "Start typing to find users"
			emptyStateLabel.isHidden = false
		} else {
			emptyStateLabel.isHidden = true
		}
	}

	private func showError(_ message: String) {
		let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
}

extension SearchVC: UISearchBarDelegate {
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		debounceTimer?.invalidate()
		debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { [weak self] _ in // 1 sec -> API can be blocked for 'too many requests' despite having API token and 10000 requests per day
			self?.performSearch(query: searchText)
		})
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		debounceTimer?.invalidate()
		performSearch(query: searchBar.text ?? "")
		searchBar.resignFirstResponder()
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		debounceTimer?.invalidate()
		viewModel.cancelSearch()
		searchBar.text = nil
		searchBar.resignFirstResponder()
		searchBar.setShowsCancelButton(false, animated: true)

		tableView.reloadData()
		emptyStateLabel.text = "Start typing to find users"
		emptyStateLabel.isHidden = false
	}
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate {
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
}
