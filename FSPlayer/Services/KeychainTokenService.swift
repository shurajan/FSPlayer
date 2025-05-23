//
//  KeychainTokenService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import Foundation
import Security

@MainActor
final class KeychainTokenService {
    static let shared = KeychainTokenService()
    
    private let serviceName = Bundle.main.bundleIdentifier ?? "com.bralnin.fsplayer"
    
    private init() {}
    
    // MARK: - Public API
    
    func saveToken(_ token: String, withKey key: String) -> Bool {
        deleteToken(withKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadToken(withKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let tokenData = result as? Data {
            return String(data: tokenData, encoding: .utf8)
        }
        
        return nil
    }
    
    func deleteToken(withKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func updateToken(_ newToken: String, withKey key: String) -> Bool {
        if loadToken(withKey: key) != nil {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: newToken.data(using: .utf8)!
            ]
            
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            return status == errSecSuccess
        } else {
            return saveToken(newToken, withKey: key)
        }
    }
    
    // MARK: - Специфичные методы для API токена
    
    func saveAPIToken(_ token: String) -> Bool {
        return saveToken(token, withKey: "apiToken")
    }
    
    func loadAPIToken() -> String? {
        return loadToken(withKey: "apiToken")
    }
    
    func deleteAPIToken() -> Bool {
        return deleteToken(withKey: "apiToken")
    }
}
