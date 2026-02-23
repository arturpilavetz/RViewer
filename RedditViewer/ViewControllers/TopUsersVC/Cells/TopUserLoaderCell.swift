//
//  TopUserLoaderCell.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 23.02.2026.
//

import UIKit
import SnapKit

final class TopUserLoaderCell: UITableViewCell {
	private let activityIndicatorView: UIActivityIndicatorView = {
		let activityIndicatorView = UIActivityIndicatorView(style: .medium)
		activityIndicatorView.color = .secondaryLabel
		activityIndicatorView.startAnimating()
		return activityIndicatorView
	}()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setConstraints()
		setUpView()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
	}
	
	private func setUpView() {
		backgroundColor = .clear
		selectionStyle = .none
	}
	
	private func setConstraints() {
		contentView.addSubview(activityIndicatorView)
		
		activityIndicatorView.snp.makeConstraints { make in
			make.size.equalTo(30)
			make.center.equalToSuperview()
		}
	}
	
	func setLoading(_ isLoading: Bool) {
		contentView.isHidden = !isLoading
		if isLoading {
			activityIndicatorView.startAnimating()
		} else {
			activityIndicatorView.stopAnimating()
		}
	}
}
