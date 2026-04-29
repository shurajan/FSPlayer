//
//  FSVideoPlayerView.swift
//  FSVideoPlayer
//

import SwiftUI
import AVKit

struct FSVideoPlayerView: View {
    
    // MARK: - Properties
    
    @Binding var seekTo: Double?

    @StateObject private var viewModel: FSVideoPlayerViewModel
    @StateObject private var sliderViewModel: FSVideoSliderViewModel
    
    var onClose: (() -> Void)?
    var buttonColor: Color
    
    @State private var isAspectFill = false
    
    private let controller: FSPlayerController
    
    // MARK: - Init
    
    init(
        controller: FSPlayerController,
        buttonColor: Color = .white,
        seekTo: Binding<Double?> = .constant(nil),
        onClose: (() -> Void)? = nil
    ) {
        self.controller = controller
        self._viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(playerController: controller))
        self._sliderViewModel = StateObject(wrappedValue: FSVideoSliderViewModel(playerController: controller))
        self.onClose = onClose
        self.buttonColor = buttonColor
        self._seekTo = seekTo
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            videoLayer
            
            if viewModel.showControls {
                controlsOverlay
            }
        }
        .onTapGesture {
            viewModel.toggleControlsVisibility()
        }
        .onAppear {
            viewModel.startPlaying()
        }
        .onDisappear {
            viewModel.cleanup()
            controller.cleanup()
            sliderViewModel.cleanup()
        }
        .onChange(of: seekTo) { _, newValue in
            if let time = newValue {
                sliderViewModel.seekImmediately(to: time)
                seekTo = nil
            }
        }
    }
    
    // MARK: - Video Layer
    
    private var videoLayer: some View {
        FSVideoPlayerLayerView(player: controller.player)
            .ignoresSafeArea()
            .onChange(of: isAspectFill) { _, newValue in
                viewModel.setAspectFill(newValue)
            }
    }
    
    // MARK: - Controls Overlay
    
    private var controlsOverlay: some View {
        VStack {
            topBar
            Spacer()
            bottomControls
        }
        .transition(.opacity)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button(action: { onClose?() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(buttonColor)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: { isAspectFill.toggle() }) {
                Image(systemName: isAspectFill 
                      ? "arrow.up.left.and.arrow.down.right" 
                      : "arrow.down.right.and.arrow.up.left")
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
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Slider
            FSVideoSlider(
                viewModel: sliderViewModel,
                onInteractionStarted: {
                    viewModel.sliderInteractionStarted()
                },
                onInteractionEnded: {
                    viewModel.sliderInteractionEnded()
                }
            )
            
            // Control Buttons (hidden but keep space when seeking)
            controlButtons
                .opacity(sliderViewModel.isSeeking ? 0 : 1)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 40) {
            controlButton(
                iconName: "gobackward.10",
                size: 40,
                action: { viewModel.skipBackward(sliderViewModel: sliderViewModel) }
            )
            
            controlButton(
                iconName: controller.isPlaying ? "pause.fill" : "play.fill",
                size: 40,
                action: { viewModel.togglePlayPause() }
            )
            
            controlButton(
                iconName: "goforward.10",
                size: 40,
                action: { viewModel.skipForward(sliderViewModel: sliderViewModel) }
            )
        }
    }
    
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
}
