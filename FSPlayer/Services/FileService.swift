//
//  FileService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//

import Foundation

// MARK: - Models

struct FileItem: Identifiable, Equatable, Codable {
    let id = UUID()
    let name: String
    let size: Int
    let resolution: String?
    let previewURL: String?
    
    enum CodingKeys: String, CodingKey {
        case name, size, resolution, previewURL
    }
}

// MARK: - Error Handling

enum FileServiceError: LocalizedError {
    case invalidToken(message: String)
    case networkError(message: String)
    case invalidResponse(message: String)
    case decodingError(message: String)
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken(let message):
            return message
        case .networkError(let message):
            return message
        case .invalidResponse(let message):
            return message
        case .decodingError(let message):
            return message
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol FileServiceProtocol {
    func fetchFiles(host: String, token: String) async -> Result<[FileItem], Error>
    func deleteFile(name: String, host: String, token: String) async -> Result<Void, Error>
}

// MARK: - Service Implementation

final class FileService: FileServiceProtocol {
    static let shared = FileService()
    
    private init() {}
    
    func fetchFiles(host: String, token: String) async -> Result<[FileItem], Error> {
        guard !token.isEmpty else {
            return .failure(FileServiceError.invalidToken(message: "Authorization token is empty"))
        }
        
        guard let url = URL(string: "http://\(host)/files") else {
            return .failure(FileServiceError.networkError(message: "Invalid URL"))
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
                return .failure(FileServiceError.invalidResponse(message: "Invalid response format"))
            }
            
            // Handle response based on status code
            switch httpResponse.statusCode {
            case 200:
                // Try to decode successful response
                do {
                    let fileItems = try JSONDecoder().decode([FileItem].self, from: data)
                    return .success(fileItems)
                } catch {
                    return .failure(FileServiceError.decodingError(message: "Failed to decode file list: \(error.localizedDescription)"))
                }
            case 401:
                return .failure(FileServiceError.invalidToken(message: "Authorization failed: Invalid or expired token"))
            default:
                // Try to decode error message if present
                if let errorMessage = String(data: data, encoding: .utf8) {
                    return .failure(FileServiceError.serverError(message: "Server error (\(httpResponse.statusCode)): \(errorMessage)"))
                } else {
                    return .failure(FileServiceError.serverError(message: "Server error: HTTP \(httpResponse.statusCode)"))
                }
            }
        } catch {
            return .failure(FileServiceError.networkError(message: "Network request failed: \(error.localizedDescription)"))
        }
    }
    
    func deleteFile(name: String, host: String, token: String) async -> Result<Void, Error> {
        guard !token.isEmpty else {
            return .failure(FileServiceError.invalidToken(message: "Authorization token is empty"))
        }

        // URL-encode имя файла для безопасного использования в URL
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "http://\(host)/files/\(encodedName)") else {
            return .failure(FileServiceError.networkError(message: "Invalid URL for file: \(name)"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(FileServiceError.invalidResponse(message: "Invalid response format"))
            }

            switch httpResponse.statusCode {
            case 200:
                return .success(())
            case 401:
                return .failure(FileServiceError.invalidToken(message: "Authorization failed: Invalid or expired token"))
            default:
                if let errorMessage = String(data: data, encoding: .utf8) {
                    return .failure(FileServiceError.serverError(message: "Server error (\(httpResponse.statusCode)): \(errorMessage)"))
                } else {
                    return .failure(FileServiceError.serverError(message: "Server error: HTTP \(httpResponse.statusCode)"))
                }
            }
        } catch {
            return .failure(FileServiceError.networkError(message: "Network request failed: \(error.localizedDescription)"))
        }
    }
    
}
