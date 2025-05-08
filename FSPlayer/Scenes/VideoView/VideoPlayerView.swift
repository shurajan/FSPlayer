//
//  VideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let selectedVideo: SelectedVideoItem
    
    @EnvironmentObject private var session: SessionStorage
    @EnvironmentObject private var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isDragging = false
    
    init(video: SelectedVideoItem, session: SessionStorage) {
        self.selectedVideo = video
        _viewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(selectedVideo: video, session: session)
        )
    }
    
    var body: some View {
        let view = background
            .gesture(dragGesture)
            .animation(.easeInOut(duration: 0.2), value: dragOffset)

        Group {
            if globalSettings.isPerformanceOverlayEnabled {
                view.performanceOverlay()
            } else {
                view
            }
        }
    }
    
    private var background: some View {
        Group {
            if let player = viewModel.player {
                FSVideoPlayerView(
                    player: player,
                    buttonColor: Color.dynamicColor(light: Color.black, dark: Color.white)) {
                        dismiss()
                    }
                    .ignoresSafeArea()
                    .onAppear { viewModel.play() }
                    .onDisappear { viewModel.cleanup() }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .padding()
            } else {
                ProgressView("Loading…")
                    .progressViewStyle(.circular)
            }
        }
        .offset(y: dragOffset.height)
        .opacity(1.0 - min(abs(dragOffset.height / 300), 1))
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { gesture in
                dragOffset = gesture.translation
            }
            .onEnded { gesture in
                if abs(gesture.translation.height) > 150 {
                    dismiss()
                } else {
                    dragOffset = .zero
                }
            }
    }
}
