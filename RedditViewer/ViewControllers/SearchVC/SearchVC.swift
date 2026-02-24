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
		tableView.registerClass(TopUserCell.self)
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

	private var users: [UserItemData] = []
	private var searchTask: Task<Void, Never>?
	private var debounceTimer: Timer?
	private var searchBarBottomConstraint: Constraint?

	private let minQueryLength = 2

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "Search"
		view.backgroundColor = .systemBackground

		searchBar.delegate = self
		tableView.dataSource = self
		tableView.delegate = self

		setUpConstraints()
		observeKeyboard()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
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
			searchTask?.cancel()
			users.removeAll()
			tableView.reloadData()
			emptyStateLabel.text = "Type at least \(minQueryLength) letters"
			emptyStateLabel.isHidden = false
			searchBar.setShowsCancelButton(false, animated: true)
			return
		}

		searchTask?.cancel()
		searchBar.setShowsCancelButton(true, animated: true)
		emptyStateLabel.text = "Searching..."
		emptyStateLabel.isHidden = false

		searchTask = Task { [weak self] in
			guard let self else { return }
			do {
				let request = try await URLRequest.usersByName(query)
				let response: StackOverflowTopUsers = try await URLSession.shared.get(request: request)
				let items = response.users ?? []

				await MainActor.run {
					self.users = items
					self.tableView.reloadData()
					self.emptyStateLabel.text = items.isEmpty ? "No users found" : ""
					self.emptyStateLabel.isHidden = !items.isEmpty
				}
			} catch is CancellationError {
				return
			} catch {
				await MainActor.run {
					self.users.removeAll()
					self.tableView.reloadData()
					self.emptyStateLabel.text = "Failed to load users"
					self.emptyStateLabel.isHidden = false
				}
			}
		}
	}
}

extension SearchVC: UISearchBarDelegate {
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		debounceTimer?.invalidate()
		debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { [weak self] _ in // 1 sec because API can be blocked for too many requests despite having API token and 10000 requests per day
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
		searchTask?.cancel()
		searchBar.text = nil
		searchBar.resignFirstResponder()
		searchBar.setShowsCancelButton(false, animated: true)

		users.removeAll()
		tableView.reloadData()
		emptyStateLabel.text = "Start typing to find users"
		emptyStateLabel.isHidden = false
	}
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate {
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
}
