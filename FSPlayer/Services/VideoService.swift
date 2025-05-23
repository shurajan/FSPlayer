//
//  FileService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//

import Foundation

// MARK: - Protocol
protocol VideoServiceProtocol {
    func fetchFiles(host: String, token: String) async -> Result<[VideoItemModel], Error>
    func deleteFile(name: String, host: String, token: String) async -> Result<Void, Error>
}

// MARK: - Service Implementation
@MainActor
final class VideoService: VideoServiceProtocol {
    static let shared = VideoService()
    
    private init() {}
    
    func fetchFiles(host: String, token: String) async -> Result<[VideoItemModel], Error> {
        guard !token.isEmpty else {
            return .failure(NetworkServiceError.invalidToken(message: "Authorization token is empty"))
        }
        
        guard let url = URL(string: "http://\(host)/videos") else {
            return .failure(NetworkServiceError.networkError(message: "Invalid URL"))
        }
        
        // Create network request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        
        do {
            // Make network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NetworkServiceError.invalidResponse(message: "Invalid response format"))
            }
            
            // Handle response based on status code
            switch httpResponse.statusCode {
            case 200:
                // Try to decode successful response
                do {
                    let fileItems = try JSONDecoder().decode([VideoItemModel].self, from: data)
                    return .success(fileItems)
                } catch {
                    return .failure(NetworkServiceError.decodingError(message: "Failed to decode file list: \(error.localizedDescription)"))
                }
            case 401:
                return .failure(NetworkServiceError.invalidToken(message: "Authorization failed: Invalid or expired token"))
            default:
                // Try to decode error message if present
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
    
    func deleteFile(name: String, host: String, token: String) async -> Result<Void, Error> {
        guard !token.isEmpty else {
            return .failure(NetworkServiceError.invalidToken(message: "Authorization token is empty"))
        }

        // URL-encode имя файла для безопасного использования в URL
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "http://\(host)/videos/\(encodedName)") else {
            return .failure(NetworkServiceError.networkError(message: "Invalid URL for file: \(name)"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NetworkServiceError.invalidResponse(message: "Invalid response format"))
            }

            switch httpResponse.statusCode {
            case 200:
                return .success(())
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
