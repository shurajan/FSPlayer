//
//  FSVideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import SwiftUI
import AVKit

struct FSVideoPlayerView: View {
    @StateObject private var viewModel: FSVideoPlayerViewModel

    var onClose: (() -> Void)?

    init(player: AVPlayer, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(player: player))
        self.onClose = onClose
    }

    @State private var isAspectFill = false

    var body: some View {
        ZStack {
            FSVideoPlayerLayerView(player: viewModel.player)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: isAspectFill) { newValue in
                    viewModel.setAspectFill(newValue)
                }

            VStack {
                topBar
                Spacer()

                if viewModel.showControls {
                    controls
                        .transition(.opacity)
                        .padding()
                }
            }
        }
        .onTapGesture {
            viewModel.toggleControls()
        }
        .onAppear {
            viewModel.startPlaying()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: {
                isAspectFill.toggle()
            }) {
                Image(systemName: isAspectFill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    private var controls: some View {
        VStack {
            Spacer()

            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding()

            Spacer()

            VStack {
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { newValue in
                            viewModel.seek(to: newValue)
                        }
                    ),
                    in: 0...viewModel.duration,
                    onEditingChanged: { editing in
                        if editing {
                            viewModel.startInteraction()
                        } else {
                            viewModel.endInteraction()
                        }
                    }
                )
                .accentColor(.red)

                HStack {
                    Text(viewModel.formattedTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(viewModel.formattedTime(viewModel.duration))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
        }
    }
}
