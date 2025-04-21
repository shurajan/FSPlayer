//
//  FSPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 16.04.2025.
//

import SwiftUI

enum NavigationDestination {
    case login
    case filesList
    case player
}

struct FSPlayerView: View {
    @State private var navigationPath = [NavigationDestination]()
    @StateObject private var session = SessionViewModel()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {

            LoginView(navigationPath: $navigationPath)
                .environmentObject(session)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .login:
                        LoginView(navigationPath: $navigationPath)
                            .environmentObject(session)
                    case .filesList:
                        MediaListView(navigationPath: $navigationPath)
                            .environmentObject(session)
                    case .player:
                        playerView
                    }
                }
        }
    }
    
    // Экран плеера
    private var playerView: some View {
        VStack(spacing: 20) {
            Text("Player Screen")
                .font(.title)
            
            Button("Back to Files") {
                navigationPath.removeLast()
            }
            .buttonStyle(.bordered)
            
            Button("Back to Login") {
                navigationPath = []
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
    }
}
