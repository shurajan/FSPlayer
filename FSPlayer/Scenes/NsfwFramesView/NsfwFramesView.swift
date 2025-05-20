//
//  NsfwFramesView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//

import SwiftUI

struct NsfwFramesView: View {
    @EnvironmentObject private var session: SessionStorage
    @EnvironmentObject private var globalSettings: GlobalSettings
    @Binding var navigationPath: [NavigationDestination]
    @StateObject private var viewModel: NsfwFramesViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(video: VideoItemModel, navigationPath: Binding<[NavigationDestination]>) {
        _viewModel = StateObject(wrappedValue: NsfwFramesViewModel(video: video))
        _navigationPath = navigationPath
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                        ForEach(viewModel.images) { imageItem in
                            NsfwImageItemView(item: imageItem, navigationPath: $navigationPath)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("NSFW Frames")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(host: session.host, token: session.token)
        }
        .withPerformanceOverlay()
    }
}
