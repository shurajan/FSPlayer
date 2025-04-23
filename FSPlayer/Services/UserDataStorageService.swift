//
//  HostStorageService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import Foundation

enum UserDefaultsKey: String, CaseIterable {
    case host = "host"
    case videoPosition = "video_position"
    
    var key: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.bralnin.fsplayer"
        return "\(bundleID).\(rawValue)"
    }
    
    func withVideoId(_ videoId: String) -> String {
        return "\(key)_\(videoId)"
    }
}

@MainActor
final class UserDataStorageService {
    static let shared = UserDataStorageService()

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
    
    // MARK: - Методы для хранения позиций видео
    
    func saveVideoPosition(_ position: Double, for videoId: String) {
        defaults.set(position, forKey: UserDefaultsKey.videoPosition.withVideoId(videoId))
    }
    
    func loadVideoPosition(for videoId: String) -> Double? {
        return defaults.double(forKey: UserDefaultsKey.videoPosition.withVideoId(videoId))
    }
    
    func clearVideoPosition(for videoId: String) {
        defaults.removeObject(forKey: UserDefaultsKey.videoPosition.withVideoId(videoId))
    }
    
    func clearAllVideoPositions() {
        let allKeys = defaults.dictionaryRepresentation().keys
        let videoPositionPrefix = "\(Bundle.main.bundleIdentifier ?? "com.bralnin.fsplayer").\(UserDefaultsKey.videoPosition.rawValue)_"
        
        allKeys.forEach { key in
            if key.hasPrefix(videoPositionPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
