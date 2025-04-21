//
//  SessionViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//

import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var token: String?
    @Published var host: String?

    init() {
        self.host = StorageService.shared.loadHost()
        self.token = KeychainTokenService.shared.loadAPIToken()
    }

    func logout() {
        token = nil
        KeychainTokenService.shared.deleteAPIToken()
    }
}
