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
    @Binding var seekTo: Double?

    @StateObject private var viewModel: FSVideoPlayerViewModel
    @StateObject private var sliderViewModel: FSVideoSliderViewModel
    
    var onClose: (() -> Void)?
    var buttonColor: Color
    
    @State private var isAspectFill = false
    private var controller: FSPlayerController
    
    init(controller: FSPlayerController,
         buttonColor: Color = .white,
         seekTo: Binding<Double?> = .constant(nil),
         onClose: (() -> Void)? = nil) {
        self.controller = controller
        _viewModel = StateObject(wrappedValue: FSVideoPlayerViewModel(playerController: controller))
        _sliderViewModel = StateObject(wrappedValue: FSVideoSliderViewModel(playerController: controller))
        self.onClose = onClose
        self.buttonColor = buttonColor
        self._seekTo = seekTo
    }
    
    var body: some View {
        ZStack {
            FSVideoPlayerLayerView(player: controller.player)
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
            
            if !sliderViewModel.isSeeking {
                controlButtons
                    .padding()
            }
            
            
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
                iconName: controller.isPlaying ? "pause.fill" : "play.fill",
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
        controller.togglePlayPause()
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
