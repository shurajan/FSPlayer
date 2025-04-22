//
//  VideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let file: FileItem

    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isDragging = false

    init(file: FileItem, session: SessionViewModel) {
        self.file = file
        _viewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(file: file, session: session)
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
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .padding()
            } else {
                ProgressView("Загружаем видео…")
                    .progressViewStyle(.circular)
            }
        }
        .offset(y: dragOffset.height)
        .opacity(1.0 - min(abs(dragOffset.height / 300), 1))
    }

    private var closeButton: some View {
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .padding()
        }
        .tint(.white)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { gesture in
                if gesture.translation.height > 0 {
                    dragOffset = gesture.translation
                }
            }
            .onEnded { gesture in
                if gesture.translation.height > 150 {
                    dismiss()
                } else {
                    dragOffset = .zero
                }
            }
    }
}
