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
    var buttonColor: Color

    @State private var isAspectFill = false

    init(player: AVPlayer, buttonColor: Color = .white, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(player: player))
        self.onClose = onClose
        self.buttonColor = buttonColor
    }

    var body: some View {
        ZStack {
            FSVideoPlayerLayerView(player: viewModel.player)
                .ignoresSafeArea()
                .onChange(of: isAspectFill) { _, newValue in
                    viewModel.setAspectFill(newValue)
                }

            VStack {
                topBar
                Spacer()

                if viewModel.showControls {
                    controls
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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(buttonColor)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            Button(action: {
                isAspectFill.toggle()
            }) {
                Image(systemName: isAspectFill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .font(.title2)
                    .foregroundColor(buttonColor)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack {
            Spacer()
            
            controlButtons
                .padding()
            
            Spacer()
            
            // Прогресс и временная информация
            progressControls
                .padding(.horizontal)
        }
        .transition(.opacity)
        .padding()
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 40) {
            controlButton(
                iconName: "gobackward.10",
                size: 40,
                action: viewModel.skipBackward
            )
            
            controlButton(
                iconName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: 50,
                action: viewModel.togglePlayPause
            )
            
            controlButton(
                iconName: "goforward.10",
                size: 40,
                action: viewModel.skipForward
            )
        }
    }

    // MARK: - Control Button
    private func controlButton(iconName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: size))
                .foregroundColor(buttonColor)
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }

    // MARK: - Progress Controls
    private var progressControls: some View {
        VStack {
            Slider(
                value: $viewModel.sliderValue,
                in: 0...viewModel.duration,
                onEditingChanged: { editing in
                    if editing {
                        viewModel.startSliderInteraction()
                    } else {
                        viewModel.updateSliderValue(viewModel.sliderValue)
                        viewModel.endSliderInteraction()
                    }
                }
            )
            .accentColor(.red)
            
            timeLabels
        }
    }

    // MARK: - Time Labels
    private var timeLabels: some View {
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
}

#Preview {
    FSVideoPlayerView(player: AVPlayer())
}
