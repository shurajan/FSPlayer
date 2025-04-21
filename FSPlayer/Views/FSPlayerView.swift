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
        switch controller.state {
        case .idle:
            Color.clear
                .onAppear {
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

        case .fileList:
            FileListView()
                .environmentObject(controller)
        }
    }
}



