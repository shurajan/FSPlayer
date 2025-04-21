//
//  LoginView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 21.04.2025.
//
import SwiftUI

struct LoginView: View {
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
