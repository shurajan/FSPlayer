//
//  FSPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 16.04.2025.
//

import SwiftUI

enum NavigationDestination {
    case login
    case videoList
}

struct FSPlayerView: View {
    @State private var navigationPath = [NavigationDestination]()
    @StateObject private var session = SessionStorage()
    @StateObject private var globalSettings = GlobalSettings()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            
            LoginView(navigationPath: $navigationPath)
                .environmentObject(session)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .login:
                        LoginView(navigationPath: $navigationPath)
                            .environmentObject(session)
                    case .videoList:
                        VideoListView(navigationPath: $navigationPath)
                            .environmentObject(session)
                            .environmentObject(globalSettings)
                    }
                }
        }
        
    }
}
