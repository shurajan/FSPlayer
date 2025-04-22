//
//  LoginView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//
import SwiftUI

struct LoginView: View {
    @Binding var navigationPath: [NavigationDestination]
    @EnvironmentObject var session: SessionViewModel
    
    @State private var host: String = StorageService.shared.loadHost() ?? ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                HostAndPortInputView(host: $host)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Login")
                    }
                }
                .disabled(isLoading)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: 400)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.large)
    }

    private func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        session.host = host
        StorageService.shared.saveHost(host)
        
        let result = await AuthService.shared.login(host: host, password: password)
        switch result {
        case .success(let newToken):
            if KeychainTokenService.shared.saveAPIToken(newToken) {
                session.token = newToken
                navigationPath.append(.filesList)
            } else {
                errorMessage = "Failed to save token"
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
