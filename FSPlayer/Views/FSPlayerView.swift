//
//  FSPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 16.04.2025.
//

import SwiftUI

struct FSPlayerView: View {
    @StateObject var controller = FSPlayerController()

    var body: some View {
        Group {
            switch controller.state {
            case .idle:
                Color.clear.onAppear {
                    controller.send(.start)
                }

            case .manualEntry:
                ManualEntryView()
                    .environmentObject(controller)

            case .needLogin(let host):
                LoginView(host: host)
                    .environmentObject(controller)

            case .loading:
                ProgressView("Logging in...")
                    .progressViewStyle(CircularProgressViewStyle())

            case .error(let error):
                VStack(spacing: 16) {
                    switch error {
                    case .authentication(let msg), .general(let msg):
                        Text("Error: \(msg)").foregroundColor(.red)
                    }
                    Button("Try Again") {
                        controller.send(.cancel)
                    }
                }

            case .success:
                Text("🎉 Welcome to FSPlayer!")
                    .font(.largeTitle)
            }
        }
        .padding()
        .animation(.easeInOut, value: controller.state)
    }
}


private struct LoginView: View {
    let host: String
    @EnvironmentObject var controller: FSPlayerController
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect to \(host)")
                .font(.title2)
                .bold()

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Login") {
                controller.send(.loginAttempted(password))
            }
            .buttonStyle(.borderedProminent)

            Button("Back") {
                controller.send(.cancel)
            }
            .foregroundColor(.secondary)
        }
    }
}
