//
//  LoginView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStorage
    @Binding             var navigationPath: [NavigationDestination]
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                HostAndPortInputView(host: $viewModel.host)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.login(session: session) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Login")
                    }
                }
                .disabled(viewModel.isLoading)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: 400)
            .padding()

            Spacer()
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: viewModel.didLogin) { oldValue, newValue in
            if newValue {
                navigationPath.append(.filesList)
            }
        }
    }
}
