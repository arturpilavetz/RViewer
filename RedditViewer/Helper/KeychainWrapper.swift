//
//  KeychainWrapper.swift
//  RedditViewer
//
//  Created by Artur Pilavetz on 24.02.2026.
//

import Foundation

@propertyWrapper
open class KeychainWrapper<Value: Codable> {
	/// Enum type on coder and encoder.
	public enum CodableType {
		case plist
		case json
	}

	/// `String` to store the value.
	private var key: String

	/// `String` to store the value.
	private var codableType: CodableType

	/// Property wrapper stored value.
	public var wrappedValue: Value? {
		get { loadValueFromKeychain() }
		set { storeValueInKeychain(newValue) }
	}

	/**
	 Create a `KeychainWrapper` property wrapper.
	 - Parameter key: `String` to store the value.
	 - Parameter codableType: `CodableType` used to encode and decode value.
	 */
	public required init(key: String, codableType: CodableType = .json) {
		self.key = key
		self.codableType = codableType
	}

	/**
	 Create a `KeychainWrapper` property wrapper with JSON codable type.
	 - Parameter key: `String` to store the value.
	 */
	public convenience init(_ key: String) {
		self.init(key: key, codableType: .json)
	}

	/**
	 Loads the value from the keychain.
	 */
	private func loadValueFromKeychain() -> Value? {
		guard let data = data(forKey: key) else {
			return nil
		}
		return codableType == .plist ? decodePlistValue(from: data) : decodeJsonValue(from: data)
	}

	/**
	 Stores the given `Value?` in the keychain.
	 - Parameter value: `Value?` that we storing to keychain.
	 */
	private func storeValueInKeychain(_ value: Value?) {
		guard let encoded = codableType == .plist ? encodePlistValue(value) : encodeJsonValue(value) else {
			removeValue(forKey: key)
			return
		}
		set(encoded, forKey: key)
	}

	/**
	 Encodes the given value to data as JSON.
	 - Parameter value: `Value?` that we encoding.
	 */
	private func encodeJsonValue(_ value: Value?) -> Data? {
		guard let value = value else {
			return nil
		}
		return try? JSONEncoder().encode(value)
	}

	/**
	 Encodes the given value to data as plist.
	 - Parameter value: `Value?` that we encoding.
	 */
	private func encodePlistValue(_ value: Value?) -> Data? {
		guard let value = value else {
			return nil
		}

		if Value.self == String.self,
			let string = value as? String {
			return Data(string.utf8)
		} else {
			return try? PropertyListEncoder().encode(value)
		}
	}

	/**
	 Decodes the value from the given data as JSON.
	 - Parameter value: `Value?` that we decoding.
	 */
	private func decodeJsonValue(from data: Data) -> Value? {
		return try? JSONDecoder().decode(Value.self, from: data)
	}

	/**
	 Decodes the value from the given data as plist.
	 - Parameter value: `Value?` that we decoding.
	 */
	private func decodePlistValue(from data: Data) -> Value? {
		if Value.self == String.self {
			return String(data: data, encoding: .utf8) as? Value
		} else {
			return try? PropertyListDecoder().decode(Value.self, from: data)
		}
	}
}
