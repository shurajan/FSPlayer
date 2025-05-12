//
//  FSVideoPlayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//  Updated on 28.04.2025.
//

import SwiftUI
import AVKit

struct FSVideoPlayerView: View {
    @StateObject private var viewModel: FSVideoPlayerViewModel
    @StateObject private var sliderViewModel: FSVideoSliderViewModel
    
    var onClose: (() -> Void)?
    var buttonColor: Color
    
    @State private var isAspectFill = false
    
    init(player: AVPlayer, buttonColor: Color = .white, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(player: player))
        _sliderViewModel = StateObject(wrappedValue: FSVideoSliderViewModel(player: player))
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
            viewModel.interact()
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
             size: 50,
             action: skipBackward
             )
            
            controlButton(
                iconName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: 50,
                action: togglePlayPause
            )
            
             controlButton(
             iconName: "goforward.10",
             size: 50,
             action: skipForward
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
                .background(Color.black.opacity(0.7))
                .clipShape(Circle())
        }
    }
    
    private func togglePlayPause() {
        viewModel.interact()
        viewModel.togglePlayPause()
        viewModel.endInteraction()
    }
    
    private func skipForward() {
        viewModel.interact()
        sliderViewModel.skipForward()
        viewModel.endInteraction()
    }
    
    private func skipBackward() {
        viewModel.interact()
        sliderViewModel.skipBackward()
        viewModel.endInteraction()
    }
    
    // MARK: - Progress Controls
    private var progressControls: some View {
        VStack {
            FSVideoSlider(
                viewModel: sliderViewModel,
                isInteracting: Binding(
                    get: { viewModel.isInteracting },
                    set: { newValue in
                        if newValue {
                            viewModel.interact()
                        } else {
                            viewModel.endInteraction()
                        }
                    }
                )
            )
        }
    }
}
