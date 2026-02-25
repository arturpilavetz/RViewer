//
//  KeychainStorage.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation
import Security

internal class KeychainStorage {

	/// `KeychainStorage` shared instance.
	fileprivate static let shared = KeychainStorage()

	/// `String` used as kSecAttrService.
	private var service: String

	/**
	 Create a `KeychainStorage`
	 - Parameter service: `String`, defaults bundle identifier.
	 */
	private init(service: String = Bundle.main.bundleIdentifier ?? "") {
		self.service = service
	}

	/**
	 Generating `[CFString: Any]` for keychain requests.
	 - Parameter key: `String` key to indentify value.
	 */
	private func query(forKey key: String) -> [CFString: Any] {
		KeychainProvider.query(secClass: .generic, service: service, account: key)
	}

	/**
	 Store `Data` value into keychain.
	 - Parameter value: `Data` value that will be saved.
	 - Parameter key: `String` to store the `Data` value.
	 */
	@discardableResult fileprivate func set(_ value: Data, forKey key: String) -> Bool {
		var query = self.query(forKey: key)
		if SecItemCopyMatching(query as CFDictionary, nil) == noErr {
			let changes = [kSecValueData: value]
			return SecItemUpdate(query as CFDictionary, changes as CFDictionary) == noErr
		}
		query[kSecValueData] = value
		return SecItemAdd(query as CFDictionary, nil) == noErr
	}

	/**
	 Get `Data` for `String` from the keychain.
	 - Parameter key: `String` to store the `Data` value.
	 */
	@discardableResult fileprivate func data(forKey key: String) -> Data? {
		var query = self.query(forKey: key)
		query[kSecReturnData] = kCFBooleanTrue
		query[kSecMatchLimit] = kSecMatchLimitOne

		var keyData: CFTypeRef?
		if SecItemCopyMatching(query as CFDictionary, &keyData) == noErr {
			guard let kd = keyData as? Data else { return nil }
			return kd
		}
		return nil
	}

	/**
	 Remove `Data` for `String` from the keychain.
	 - Parameter key: `String` to remove the `Data` value.
	 */
	@discardableResult fileprivate func removeValue(forKey key: String) -> Bool {
		let keyChain = self.query(forKey: key)
		return SecItemDelete(keyChain as CFDictionary) == noErr
	}
}

extension KeychainWrapper {
	/**
	 Get `Data` for `String` from the keychain.
	 - Parameter key: `String` to store the `Data` value.
	 */
	internal func data(forKey key: String) -> Data? {
		KeychainStorage.shared.data(forKey: key)
	}

	/**
	 Store `Data` value into keychain.
	 - Parameter value: `Data` value that will be saved.
	 - Parameter key: `String` to store the `Data` value.
	 */
	internal func set(_ value: Data, forKey key: String) {
		KeychainStorage.shared.set(value, forKey: key)
	}

	/**
	 Remove `Data` for `String` from the keychain.
	 - Parameter key: `String` to remove the `Data` value.
	 */
	internal func removeValue(forKey key: String) {
		KeychainStorage.shared.removeValue(forKey: key)
	}
}
