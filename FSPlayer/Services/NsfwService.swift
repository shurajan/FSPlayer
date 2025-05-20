//
//  NsfwService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//

import Foundation

// MARK: - Protocol

protocol NsfwServiceProtocol {
    func fetchFiles(host: String, url: String, token: String) async -> Result<[ImageItemModel], Error>
}

// MARK: - Service Implementation
@MainActor
final class NsfwService: NsfwServiceProtocol {
    static let shared = NsfwService()
    
    private init() {}
    
    func fetchFiles(host: String, url: String, token: String) async -> Result<[ImageItemModel], Error> {
        guard !token.isEmpty else {
            return .failure(NetworkServiceError.invalidToken(message: "Authorization token is empty"))
        }

        guard let fullURL = URL(string: "http://\(host)\(url)") else {
            return .failure(NetworkServiceError.networkError(message: "Invalid URL"))
        }

        var request = URLRequest(url: fullURL)
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
                do {
                    let result = try JSONDecoder().decode([String: [String]].self, from: data)
                    let filenames = result["files"] ?? []
                    let items = ImageItemModel.models(from: filenames, basePath: url)
                    return .success(items)
                } catch {
                    return .failure(NetworkServiceError.decodingError(message: "Failed to decode: \(error.localizedDescription)"))
                }
            case 401:
                return .failure(NetworkServiceError.invalidToken(message: "Unauthorized"))
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown"
                return .failure(NetworkServiceError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)"))
            }
        } catch {
            return .failure(NetworkServiceError.networkError(message: "Request failed: \(error.localizedDescription)"))
        }
    }
}
