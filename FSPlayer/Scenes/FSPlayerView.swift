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
}

struct FSPlayerView: View {
    @State private var navigationPath = [NavigationDestination]()
    @StateObject private var session = SessionStorage()
    
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
                        VideoListView(navigationPath: $navigationPath)
                            .environmentObject(session)
                    }
                }
        }
        
    }
}
