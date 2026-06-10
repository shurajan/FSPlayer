//
//  VideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: VideoPlayerViewModel

    init(video: VideoItemModel, session: SessionStorage) {
        _viewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(selectedVideo: video, session: session)
        )
    }

    var body: some View {
        Group {
            if let controller = viewModel.playerController {
                FSVideoPlayerView(controller: controller) {
                    dismiss()
                }
                .ignoresSafeArea(edges: [.top])
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
        .withPerformanceOverlay()
    }
}
