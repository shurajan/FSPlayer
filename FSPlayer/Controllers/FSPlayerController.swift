//
//  FSPlayerViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 16.04.2025.
//

import SwiftUI
import Network
import dnssd

enum AppError: Equatable {
    case authentication(String)
    case general(String)
}

@MainActor
final class FSPlayerController: ObservableObject {

    @Published private(set) var state: State = .idle

    enum State: Equatable{
        case idle
        case manualEntry
        case needLogin(host: String)
        case loading
        case error(AppError)
        case success
    }

    enum Event {
        case start
        case hostEntered(String)
        case loginAttempted(String)
        case loginFailed(String)
        case loginSucceeded
        case cancel
    }

    private(set) var currentHost: String?
    private var password: String = ""

    func send(_ event: Event) {
        switch (state, event) {
        case (.idle, .start):
            state = .manualEntry

        case (.manualEntry, .hostEntered(let host)):
            currentHost = host
            state = .needLogin(host: host)

        case (.needLogin(let host), .loginAttempted(let password)):
            self.password = password
            state = .loading
            Task {
                await handleLogin(for: host, password: password)
            }

        case (.loading, .loginSucceeded):
            state = .success

        case (.loading, .loginFailed(let message)):
            state = .error(.authentication(message))

        case (_, .cancel):
            state = .manualEntry

        default:
            break
        }
    }

    private func handleLogin(for host: String, password: String) async {
        let result = await AuthService.shared.login(host: host, password: password)
        
        switch result {
        case .success:
            send(.loginSucceeded)
        case .failure(let error):
            send(.loginFailed(error.localizedDescription))
        }
    }
    
}

