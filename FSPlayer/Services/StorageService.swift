//
//  HostStorageService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import Foundation

enum UserDefaultsKey: String {
    case host = "host"
    
    var key: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.bralnin.fsplayer"
        return "\(bundleID).\(rawValue)"
    }
}

final class StorageService {
    static let shared = StorageService()

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveHost(_ value: String) {
        defaults.set(value, forKey: UserDefaultsKey.host.key)
    }

    func loadHost() -> String? {
        defaults.string(forKey: UserDefaultsKey.host.key)
    }

    func clear() {
        defaults.removeObject(forKey: UserDefaultsKey.host.key)
    }
    
    // MARK: - Общие методы
    
    func save<T>(_ value: T, forKey key: UserDefaultsKey) {
        defaults.set(value, forKey: key.key)
    }
    
    func load<T>(forKey key: UserDefaultsKey) -> T? {
        return defaults.object(forKey: key.key) as? T
    }
    
    func clear(key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.key)
    }
}

// Для поддержки перечисления всех ключей, если потребуется в будущем
extension UserDefaultsKey: CaseIterable {}
