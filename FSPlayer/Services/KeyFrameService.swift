//
//  KeyFrameService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 12.05.2025.
//

import Foundation
import UIKit

// MARK: - Error Handling

enum KeyFrameServiceError: LocalizedError {
    case invalidToken(message: String)
    case invalidURL(message: String)
    case networkError(message: String)
    case invalidResponse(message: String)
    case imageDecodeError(message: String)
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken(let message),
             .invalidURL(let message),
             .networkError(let message),
             .invalidResponse(let message),
             .imageDecodeError(let message),
             .serverError(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol KeyFrameServiceProtocol {
    func fetchImage(from urlPath: String, host: String, token: String) async -> Result<UIImage, Error>
}

// MARK: - Service Implementation

@MainActor
final class KeyFrameService: KeyFrameServiceProtocol {
    static let shared = KeyFrameService()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 2000
        cache.totalCostLimit = 256 * 1024 * 1024 
    }

    func fetchImage(from urlPath: String, host: String, token: String) async -> Result<UIImage, Error> {
        guard !token.isEmpty else {
            return .failure(KeyFrameServiceError.invalidToken(message: "Authorization token is empty"))
        }
        
        guard let url = URL(string: "http://\(host)\(urlPath)") else {
            return .failure(KeyFrameServiceError.invalidURL(message: "Invalid image URL"))
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        if let cachedImage = cache.object(forKey: cacheKey) {
            return .success(cachedImage)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(KeyFrameServiceError.invalidResponse(message: "Invalid response format"))
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let image = UIImage(data: data) else {
                    return .failure(KeyFrameServiceError.imageDecodeError(message: "Failed to decode image data"))
                }

                let cost = data.count
                cache.setObject(image, forKey: cacheKey, cost: cost)
                return .success(image)
            case 401:
                return .failure(KeyFrameServiceError.invalidToken(message: "Authorization failed: Invalid or expired token"))
            default:
                if let errorMessage = String(data: data, encoding: .utf8) {
                    return .failure(KeyFrameServiceError.serverError(message: "Server error (\(httpResponse.statusCode)): \(errorMessage)"))
                } else {
                    return .failure(KeyFrameServiceError.serverError(message: "Server error: HTTP \(httpResponse.statusCode)"))
                }
            }
        } catch {
            return .failure(KeyFrameServiceError.networkError(message: "Network request failed: \(error.localizedDescription)"))
        }
    }
}
