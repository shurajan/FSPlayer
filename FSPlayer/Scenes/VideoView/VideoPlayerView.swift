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
        ZStack(alignment: .topLeading) {
            background
                .gesture(dragGesture)

            closeButton
        }
        .animation(.easeInOut(duration: 0.2), value: dragOffset)
    }

    private var background: some View {
        Group {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { viewModel.play() }
                    .onDisappear { viewModel.cleanup() }
                    .onTapGesture {
                        print("Tapped")
                    }
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

    private var closeButton: some View {
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .padding(.leading, 16)
                .padding(.top, 30)
        }
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
                let verticalAmount = gesture.translation.height
                if abs(verticalAmount) > 150 {
                    dismiss()
                } else {
                    dragOffset = .zero
                }
            }
    }
}
