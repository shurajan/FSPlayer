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
    @Published private(set) var token: String? = KeychainTokenService.shared.loadAPIToken()
    
    @Published private(set) var files: [FileItem] = []
    
    enum State: Equatable{
        case idle
        case manualEntry
        case needLogin(host: String)
        case loading
        case error(AppError)
        case success
        case fileList([FileItem])
    }
    
    enum Event {
        case start
        case hostEntered(String)
        case loginAttempted(String)
        case loginFailed(String)
        case loginSucceeded
        case cancel
        case fetchFiles
        case filesFetched([FileItem])
        case filesFetchFailed(String)
    }
    
    private(set) var currentHost: String? = UserDataStorageService.shared.loadHost()
    private var password: String = ""
    
    func send(_ event: Event) {
        switch (state, event) {
        case (.idle, .start):
            if let token, let currentHost {
                state = .loading
                Task {
                    await fetchFilesList()
                }
            } else {
                state = .manualEntry
            }
            
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
            state = .loading
            Task {
                await fetchFilesList()
            }
            
        case (.loading, .loginFailed(let message)):
            state = .error(.authentication(message))
            
        case (.loading, .filesFetched(let fileItems)):
            files = fileItems
            state = .fileList(fileItems)
            
        case (.loading, .filesFetchFailed(let message)):
            state = .error(.general(message))
            
        case (_, .cancel):
            state = .manualEntry
            
        default:
            break
        }
    }
    
    
    
    private func handleLogin(for host: String, password: String) async {
        if let token  {
            print(token)
        }
        
        let result = await AuthService.shared.login(host: host, password: password)
        
        switch result {
        case .success(let newToken):
            if KeychainTokenService.shared.saveAPIToken(newToken) {
                token = newToken
            } else {
                send(.loginFailed("Faield to save token"))
            }
            send(.loginSucceeded)
        case .failure(let error):
            send(.loginFailed(error.localizedDescription))
        }
    }
    
    func fetchFilesList() async {
        guard let host = currentHost, let token = token else {
            send(.filesFetchFailed("Missing host or authentication token"))
            return
        }
        
        let result = await VideoService.shared.fetchFiles(host: host, token: token)
        
        switch result {
        case .success(let fileItems):
            send(.filesFetched(fileItems))
        case .failure(let error):
            send(.filesFetchFailed(error.localizedDescription))
        }
    }
    
}

