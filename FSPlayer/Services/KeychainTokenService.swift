//
//  KeychainTokenService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import Foundation
import Security

final class KeychainTokenService {
    static let shared = KeychainTokenService()
    
    private let serviceName = Bundle.main.bundleIdentifier ?? "com.bralnin.fsplayer"
    
    private init() {}
    
    // MARK: - Public API
    
    func saveToken(_ token: String, withKey key: String) -> Bool {
        // Удалим старый токен, если он существует
        deleteToken(withKey: key)
        
        // Создаем словарь для сохранения в Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Добавляем новый токен
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadToken(withKey key: String) -> String? {
        // Создаем запрос для получения токена
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Выполняем запрос
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Обрабатываем результат
        if status == errSecSuccess, let tokenData = result as? Data {
            return String(data: tokenData, encoding: .utf8)
        }
        
        return nil
    }
    
    func deleteToken(withKey key: String) -> Bool {
        // Создаем запрос для удаления токена
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Удаляем токен
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // Метод для обновления токена
    func updateToken(_ newToken: String, withKey key: String) -> Bool {
        // Проверяем существует ли такой токен
        if loadToken(withKey: key) != nil {
            // Создаем запрос для поиска существующей записи
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key
            ]
            
            // Создаем словарь с новыми данными
            let attributes: [String: Any] = [
                kSecValueData as String: newToken.data(using: .utf8)!
            ]
            
            // Обновляем запись
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            return status == errSecSuccess
        } else {
            // Если токен не существует, создаем новый
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
