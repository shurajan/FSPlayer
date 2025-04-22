//
//  LoginViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: — Published state
    @Published var host: String = UserDataStorageService.shared.loadHost() ?? ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var didLogin: Bool = false

    // MARK: — dependencies
    private let storage   = UserDataStorageService.shared
    private let auth      = AuthService.shared
    private let keychain  = KeychainTokenService.shared

    // MARK: — Intent: login
    func login(session: SessionStorage) async {
        errorMessage = nil
        isLoading    = true
        didLogin = false
        defer { isLoading = false }

        session.host = host
        storage.saveHost(host)

        let result = await auth.login(host: host, password: password)
        switch result {
        case .success(let token):
            if keychain.saveAPIToken(token) {
                session.token  = token
                didLogin       = true
            } else {
                errorMessage = "Can't save token"
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
