//
//  AnalysisService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 27.05.2025.
//

import Foundation

// MARK: - Protocol

protocol AnalysisServiceProtocol {
    func start(name: String, host: String, token: String) async -> Result<NsfwScanResponse, Error>
}

// MARK: - Service Implementation

@MainActor
final class AnalysisService: AnalysisServiceProtocol {
    static let shared = AnalysisService()
    
    private init() {}
    
    func start(name: String, host: String, token: String) async -> Result<NsfwScanResponse, Error> {
        guard !token.isEmpty else {
            return .failure(NetworkServiceError.invalidToken(message: "Authorization token is empty"))
        }

        guard let fullURL = URL(string: "http://\(host)/nsfw-scan/\(name)") else {
            return .failure(NetworkServiceError.networkError(message: "Invalid URL"))
        }

        var request = URLRequest(url: fullURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.httpBody = Data() // Explicit empty body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NetworkServiceError.invalidResponse(message: "Invalid response format"))
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoded = try JSONDecoder().decode(NsfwScanResponse.self, from: data)
                    return .success(decoded)
                } catch {
                    return .failure(NetworkServiceError.decodingError(message: "Failed to decode: \(error.localizedDescription)"))
                }
            case 401:
                return .failure(NetworkServiceError.invalidToken(message: "Unauthorized"))
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(NetworkServiceError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)"))
            }
        } catch {
            return .failure(NetworkServiceError.networkError(message: "Request failed: \(error.localizedDescription)"))
        }
    }
}
