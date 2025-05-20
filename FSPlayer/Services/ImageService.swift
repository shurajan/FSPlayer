//
//  KeyFrameService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 12.05.2025.
//

import Foundation
import UIKit


// MARK: - Protocol

protocol ImageServiceProtocol {
    func fetchImage(from urlPath: String, host: String, token: String) async -> Result<UIImage, Error>
}

// MARK: - Service Implementation

@MainActor
final class ImageService: ImageServiceProtocol {
    static let shared = ImageService()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 2000
        cache.totalCostLimit = 256 * 1024 * 1024 
    }

    func fetchImage(from urlPath: String, host: String, token: String) async -> Result<UIImage, Error> {
        guard !token.isEmpty else {
            return .failure(NetworkServiceError.invalidToken(message: "Authorization token is empty"))
        }
        
        guard let url = URL(string: "http://\(host)\(urlPath)") else {
            return .failure(NetworkServiceError.invalidURL(message: "Invalid image URL"))
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
                return .failure(NetworkServiceError.invalidResponse(message: "Invalid response format"))
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let image = UIImage(data: data) else {
                    return .failure(NetworkServiceError.imageDecodeError(message: "Failed to decode image data"))
                }

                let cost = data.count
                cache.setObject(image, forKey: cacheKey, cost: cost)
                return .success(image)
            case 401:
                return .failure(NetworkServiceError.invalidToken(message: "Authorization failed: Invalid or expired token"))
            default:
                if let errorMessage = String(data: data, encoding: .utf8) {
                    return .failure(NetworkServiceError.serverError(message: "Server error (\(httpResponse.statusCode)): \(errorMessage)"))
                } else {
                    return .failure(NetworkServiceError.serverError(message: "Server error: HTTP \(httpResponse.statusCode)"))
                }
            }
        } catch {
            return .failure(NetworkServiceError.networkError(message: "Network request failed: \(error.localizedDescription)"))
        }
    }
}
