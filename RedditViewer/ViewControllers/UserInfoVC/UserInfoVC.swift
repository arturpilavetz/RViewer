//
//  UserInfoVC.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import UIKit
import SnapKit
import Photos

final class UserInfoVC: UIViewController {
	private let scrollView = UIScrollView()
	private let contentView = UIView()
	private let stackView: UIStackView = {
		let stack = UIStackView()
		stack.axis = .vertical
		stack.spacing = 12
		return stack
	}()

	private let avatarImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 40
		imageView.backgroundColor = .systemGray5
		return imageView
	}()

	private let nameLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 24)
		label.textColor = .label
		label.textAlignment = .center
		label.numberOfLines = 0
		return label
	}()

	private let repLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 16, weight: .semibold)
		label.textColor = .secondaryLabel
		label.textAlignment = .center
		return label
	}()

	private let badgesLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 15, weight: .medium)
		label.textAlignment = .center
		return label
	}()

	private var imageTask: Task<Void, Never>?
	private var toastBottomConstraint: Constraint?
	private var toastHideTask: DispatchWorkItem?
	private var loadedAvatarImage: UIImage?
	private var isSavedUser = false

	private let user: UserItemData
	private let savedUsersStore: SavedUsersStoring
	private lazy var saveButtonItem = UIBarButtonItem(
		image: nil,
		style: .plain,
		target: self,
		action: #selector(toggleSavedUser)
	)

	private let copyToastView: UIView = {
		let view = UIView()
		view.backgroundColor = .tertiarySystemBackground
		view.layer.cornerRadius = 18
		view.layer.borderWidth = 1
		view.alpha = 0
		return view
	}()

	private let copyToastLabel: UILabel = {
		let label = UILabel()
		label.text = "Text copied"
		label.textColor = .label
		label.font = .systemFont(ofSize: 13, weight: .semibold)
		label.textAlignment = .center
		return label
	}()

	init(user: UserItemData, savedUsersStore: SavedUsersStoring) {
		self.user = user
		self.savedUsersStore = savedUsersStore
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBackground
		title = "User Info"
		navigationItem.rightBarButtonItem = saveButtonItem

		setUpConstraints()
		setUpGestures()
		loadData()
		refreshSavedState()
		updateColors()
	}

	deinit {
		imageTask?.cancel()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
	}

	private func setUpConstraints() {
		view.addSubview(scrollView)
		scrollView.addSubview(contentView)
		contentView.addSubviews([
			avatarImageView,
			nameLabel,
			repLabel,
			badgesLabel,
			stackView
		])
		view.addSubview(copyToastView)
		copyToastView.addSubview(copyToastLabel)

		scrollView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}

		contentView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
			make.width.equalTo(scrollView.snp.width)
		}

		avatarImageView.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(20)
			make.centerX.equalToSuperview()
			make.size.equalTo(CGSize(width: 80, height: 80))
		}

		nameLabel.snp.makeConstraints { make in
			make.top.equalTo(avatarImageView.snp.bottom).offset(12)
			make.leading.trailing.equalToSuperview().inset(20)
		}

		repLabel.snp.makeConstraints { make in
			make.top.equalTo(nameLabel.snp.bottom).offset(8)
			make.leading.trailing.equalToSuperview().inset(20)
		}

		badgesLabel.snp.makeConstraints { make in
			make.top.equalTo(repLabel.snp.bottom).offset(8)
			make.leading.trailing.equalToSuperview().inset(20)
		}

		stackView.snp.makeConstraints { make in
			make.top.equalTo(badgesLabel.snp.bottom).offset(20)
			make.leading.trailing.equalToSuperview().inset(16)
			make.bottom.equalToSuperview().inset(50)
		}

		copyToastView.snp.makeConstraints { make in
			make.centerX.equalToSuperview()
			make.height.equalTo(36)
			make.width.greaterThanOrEqualTo(120)
			toastBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(80).constraint
		}

		copyToastLabel.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14))
		}
	}

	private func setUpGestures() {
		avatarImageView.isUserInteractionEnabled = true
		let avatarLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleAvatarLongPress(_:)))
		avatarLongPress.minimumPressDuration = 0.35
		avatarImageView.addGestureRecognizer(avatarLongPress)
	}

	private func loadData() {
		nameLabel.text = user.displayName ?? "Unknown User"
		repLabel.text = "Reputation: \(UserPresentationFormatter.compactCount(user.reputation ?? 0))"
		badgesLabel.attributedText = UserPresentationFormatter.badgesText(user.badgeCounts)

		addInfoRow(title: "User ID", value: user.userID.map(String.init) ?? "-")
		addInfoRow(title: "Account ID", value: user.accountID.map(String.init) ?? "-")
		addInfoRow(title: "User Type", value: user.userType?.presentationTitle ?? "-")
		addInfoRow(title: "Accept Rate", value: user.acceptRate.map { "\($0)%" } ?? "-")
		addInfoRow(title: "Location", value: user.location ?? "-")
		addInfoRow(title: "Website", value: user.websiteURL ?? "-")
		addInfoRow(title: "Profile Link", value: user.link ?? "-")
		addInfoRow(title: "Created", value: UserPresentationFormatter.unixDate(user.creationDate))
		addInfoRow(title: "Last Access", value: UserPresentationFormatter.unixDate(user.lastAccessDate))
		addInfoRow(title: "Last Modified", value: UserPresentationFormatter.unixDate(user.lastModifiedDate))

		loadImage(urlString: user.profileImage)
	}

	private func refreshSavedState() {
		isSavedUser = savedUsersStore.isSaved(user: user)
		updateSaveButtonAppearance()
	}

	private func updateSaveButtonAppearance() {
		let imageName = isSavedUser ? "bookmark.fill" : "bookmark"
		saveButtonItem.image = UIImage(systemName: imageName)
		saveButtonItem.accessibilityLabel = isSavedUser ? "Remove from saved" : "Save user"
	}

	private func addInfoRow(title: String, value: String) {
		let container = UserInfoRowView(copyValue: value)
		container.backgroundColor = .secondarySystemBackground
		container.layer.cornerRadius = 10
		container.layer.borderWidth = 1
		container.layer.borderColor = UIColor.separator.cgColor
		container.isUserInteractionEnabled = true

		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleRowLongPress(_:)))
		longPress.minimumPressDuration = 0.35
		container.addGestureRecognizer(longPress)

		let titleLabel = UILabel()
		titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
		titleLabel.textColor = .secondaryLabel
		titleLabel.text = title

		let valueLabel = UILabel()
		valueLabel.font = .systemFont(ofSize: 15)
		valueLabel.textColor = .label
		valueLabel.numberOfLines = 0
		valueLabel.text = value

		container.addSubviews([titleLabel, valueLabel])

		titleLabel.snp.makeConstraints { make in
			make.top.leading.trailing.equalToSuperview().inset(12)
		}
		valueLabel.snp.makeConstraints { make in
			make.top.equalTo(titleLabel.snp.bottom).offset(4)
			make.leading.trailing.bottom.equalToSuperview().inset(12)
		}

		stackView.addArrangedSubview(container)
	}

	private func updateColors() {
		copyToastView.layer.borderColor = UIColor.separator.cgColor
		for arrangedSubview in stackView.arrangedSubviews {
			arrangedSubview.layer.borderColor = UIColor.separator.cgColor
		}
	}

	@objc private func handleRowLongPress(_ recognizer: UILongPressGestureRecognizer) {
		guard recognizer.state == .began,
			  let row = recognizer.view as? UserInfoRowView else { return }

		UIPasteboard.general.string = row.copyValue
		UINotificationFeedbackGenerator().notificationOccurred(.success)
		showToast(message: "Text copied")
	}

	@objc private func handleAvatarLongPress(_ recognizer: UILongPressGestureRecognizer) {
		guard recognizer.state == .began else { return }
		saveAvatarImageToPhotos()
	}

	@objc private func toggleSavedUser() {
		do {
			if isSavedUser {
				try savedUsersStore.remove(user: user)
				isSavedUser = false
				UINotificationFeedbackGenerator().notificationOccurred(.success)
				showToast(message: "Removed from saved")
			} else {
				try savedUsersStore.save(user: user)
				isSavedUser = true
				UINotificationFeedbackGenerator().notificationOccurred(.success)
				showToast(message: "Saved user")
			}
			updateSaveButtonAppearance()
		} catch SavedUsersStoreError.missingUserIdentifier {
			UINotificationFeedbackGenerator().notificationOccurred(.error)
			showToast(message: "Cannot save user without ID")
		} catch {
			UINotificationFeedbackGenerator().notificationOccurred(.error)
			showToast(message: "Failed to update saved user")
		}
	}

	private func saveAvatarImageToPhotos() {
		guard let image = loadedAvatarImage else {
			UINotificationFeedbackGenerator().notificationOccurred(.error)
			showToast(message: "Image is not loaded yet")
			return
		}

		requestPhotoAccessAndSave(image)
	}

	private func requestPhotoAccessAndSave(_ image: UIImage) {
		if #available(iOS 14, *) {
			PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
				guard let self else { return }
				switch status {
					case .authorized, .limited:
						self.saveImage(image)
					case .denied, .restricted:
						DispatchQueue.main.async {
							UINotificationFeedbackGenerator().notificationOccurred(.error)
							self.showToast(message: "Allow Photos access in Settings")
						}
					case .notDetermined:
						break
					@unknown default:
						DispatchQueue.main.async {
							UINotificationFeedbackGenerator().notificationOccurred(.error)
							self.showToast(message: "Photos permission error")
						}
				}
			}
		} else {
			PHPhotoLibrary.requestAuthorization { [weak self] status in
				guard let self else { return }
				if status == .authorized {
					self.saveImage(image)
				} else {
					DispatchQueue.main.async {
						UINotificationFeedbackGenerator().notificationOccurred(.error)
						self.showToast(message: "Allow Photos access in Settings")
					}
				}
			}
		}
	}

	private func saveImage(_ image: UIImage) {
		PHPhotoLibrary.shared().performChanges({
			PHAssetChangeRequest.creationRequestForAsset(from: image)
		}) { [weak self] success, _ in
			DispatchQueue.main.async {
				guard let self else { return }
				if success {
					UINotificationFeedbackGenerator().notificationOccurred(.success)
					self.showToast(message: "Image saved")
				} else {
					UINotificationFeedbackGenerator().notificationOccurred(.error)
					self.showToast(message: "Failed to save image")
				}
			}
		}
	}

	private func showToast(message: String) {
		toastHideTask?.cancel()
		copyToastLabel.text = message
		view.layoutIfNeeded()
		toastBottomConstraint?.update(offset: -16)

		UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut]) {
			self.copyToastView.alpha = 1
			self.view.layoutIfNeeded()
		}

		let workItem = DispatchWorkItem { [weak self] in
			guard let self else { return }
			self.toastBottomConstraint?.update(offset: 80)
			UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
				self.copyToastView.alpha = 0
				self.view.layoutIfNeeded()
			}
		}

		toastHideTask = workItem
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
	}

	private func loadImage(urlString: String?) {
		let placeholder = UIImage(systemName: "person.crop.circle")
		avatarImageView.image = placeholder
		loadedAvatarImage = nil
		imageTask = Task {
			let image = await AvatarImageLoader.shared.image(for: urlString)
			guard !Task.isCancelled else { return }
			await MainActor.run {
				self.loadedAvatarImage = image
				self.avatarImageView.image = image ?? placeholder
			}
		}
	}
}
