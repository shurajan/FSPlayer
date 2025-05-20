//
//  ServiceError.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//
import Foundation

enum NetworkServiceError: LocalizedError {
    case invalidToken(message: String)
    case invalidURL(message: String)
    case networkError(message: String)
    case invalidResponse(message: String)
    case decodingError(message: String)
    case imageDecodeError(message: String)
    case invalidPassword(message: String)
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken(let message),
                .invalidURL(message: let message),
                .networkError(let message),
                .invalidResponse(let message),
                .decodingError(let message),
                .imageDecodeError(let message),
                .invalidPassword(let message),
                .serverError(let message):
            return message
        }
    }
}
