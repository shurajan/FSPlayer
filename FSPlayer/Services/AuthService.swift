//
//  AuthService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 17.04.2025.
//
import Foundation

enum AuthError: LocalizedError {
    case invalidPassword(message: String)
    case networkError(message: String)
    case invalidResponse(message: String)
    case decodingError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPassword(let message):
            return message
        case .networkError(let message):
            return message
        case .invalidResponse(let message):
            return message
        case .decodingError(let message):
            return message
        }
    }
}

protocol AuthServiceProtocol {
    func login(host: String, password: String) async -> Result<String, Error>
}

struct AuthResponse: Decodable {
    let token: String
}

struct AuthErrorResponse: Decodable {
    let error: String
}

@MainActor
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private init() {}
    
    func login(host: String, password: String) async -> Result<String, Error> {
        guard let url = URL(string: "http://\(host)/auth") else {
            return .failure(AuthError.networkError(message: "Invalid URL"))
        }
        
        // Prepare request body
        let requestBody = ["password": password]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return .failure(AuthError.networkError(message: "Failed to serialize request body"))
        }
        
        // Create network request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            // Make network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(AuthError.invalidResponse(message: "Invalid response format"))
            }
            
            // Handle response based on status code
            if httpResponse.statusCode == 200 {
                // Try to decode successful response
                if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    return .success(authResponse.token)
                } else {
                    return .failure(AuthError.decodingError(message: "Failed to decode successful response"))
                }
            } else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    return .failure(AuthError.invalidPassword(message: errorResponse.error))
                } else {
                    return .failure(AuthError.invalidResponse(message: "HTTP Error: \(httpResponse.statusCode)"))
                }
            }
        } catch {
            return .failure(AuthError.networkError(message: "Network request failed: \(error.localizedDescription)"))
        }
    }
}
