//
//  VideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let selectedVideo: VideoItemModel
    @State private var seekToTime: Double? = nil

    @EnvironmentObject private var globalSettings: GlobalSettings
    @EnvironmentObject private var session: SessionStorage
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var showKeyframes: Bool = false

    @State private var keyframeInitialIndex: Int = 0

    init(video: VideoItemModel, session: SessionStorage) {
        self.selectedVideo = video
        _viewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(selectedVideo: video, session: session)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            let view = background
                .gesture(revealKeyframeGesture)
                .animation(.easeInOut(duration: 0.2), value: dragOffset)
                .animation(.easeInOut(duration: 0.25), value: showKeyframes)

            if globalSettings.isPerformanceOverlayEnabled {
                view.performanceOverlay()
            } else {
                view
            }

            if showKeyframes,
               let keyframesURL = selectedVideo.keyframesURL {
                LazyKeyframeSliderView(
                    segmentCount: selectedVideo.segmentCount ?? 0,
                    keyframesURL: keyframesURL,
                    thumbnailHeight: 150,
                    onTap: { index in
                        guard let segmentDuration = selectedVideo.avgSegmentDuration else { return }
                        let maxDuration = Double(selectedVideo.duration)
                        let targetTime = Double(index) * segmentDuration
                        seekToTime = min(targetTime, maxDuration)
                    },
                    initialIndex: keyframeInitialIndex
                )
                .environmentObject(session)
                .frame(height: 150)
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    private func updateInitialKeyframeIndex() {
        guard let segmentDuration = selectedVideo.avgSegmentDuration,
              let player = viewModel.player else { return }

        let currentTime = player.currentTime().seconds
        let index = max(0, Int(currentTime / segmentDuration))
        keyframeInitialIndex = index//min(index, (selectedVideo.segmentCount ?? 1) - 1)
    }

    private var background: some View {
        Group {
            if let controller = viewModel.playerController {
                FSVideoPlayerView(
                    controller: controller,
                    buttonColor: Color.dynamicColor(light: .black, dark: .white),
                    seekTo: $seekToTime
                ) {
                    dismiss()
                }
                .ignoresSafeArea(edges: [.top])
                .onAppear {
                    viewModel.play()
                }
                .onDisappear {
                    viewModel.cleanup()
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

    private var revealKeyframeGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { gesture in
                dragOffset = gesture.translation
            }
            .onEnded { gesture in
                if gesture.translation.height < -100 {
                    updateInitialKeyframeIndex()
                    showKeyframes = true
                } else if gesture.translation.height > 100 {
                    showKeyframes = false
                }
                dragOffset = .zero
            }
    }
}
