//
//  AuthService.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 17.04.2025.
//
import Foundation

enum AuthError: LocalizedError {
    case invalidPassword(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidPassword(let message):
            return message
        }
    }
}

protocol AuthServiceProtocol {
    func login(host: String, password: String) async -> Result<String, Error>
}

final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private init() {}
    
    func login(host: String, password: String) async -> Result<String, Error> {
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        if password == "1234" {
            return .success("token")
        } else {
            return .failure(AuthError.invalidPassword(message: "Wrong password for host \(host)"))
        }
    }
}
