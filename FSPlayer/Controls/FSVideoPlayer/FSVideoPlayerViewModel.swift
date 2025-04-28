//
//  FSVideoPlayerViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//  Updated on 28.04.2025.
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
final class FSVideoPlayerViewModel: ObservableObject {
    // MARK: - Properties
    let player: AVPlayer
    private var cachedPlayerLayer: AVPlayerLayer?
    private var timerService = HideControlsTimerService()
    private var cancellables = Set<AnyCancellable>()
    private var interactingController = InteractingController()
    private var interactingTask = SafeTask()
    
    @Published private(set) var isInteracting = false
    @Published var isPlaying = false
    @Published var showControls = false
    
    // MARK: - Initialization
    init(player: AVPlayer) {
        self.player = player
        observeInteractingChanges()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.cleanup()
        }
    }
    
    // MARK: - Playback Controls
    func startPlaying() {
        player.play()
        isPlaying = true
        
        timerService.configure(timeout: 3) { [weak self] in
            guard let self else { return }
            if !self.isInteracting {
                self.showControls = false
            }
        }
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    // MARK: - User Interaction
    func interact() {
        Task { [weak self] in
            await self?.interactingController.startInteraction()
        }
    }

    func endInteraction() {
        Task { [weak self] in
            await self?.interactingController.endInteraction()
        }
    }
    
    private func observeInteractingChanges() {
        interactingTask.start { [weak self] in
            guard let self else { return }
            for await isActive in await interactingController.interactingChanges {
                await MainActor.run {
                    self.isInteracting = isActive
                    if isActive {
                        self.timerService.stop()
                        self.showControls = true
                    } else {
                        self.showControls = true
                        self.timerService.start()
                    }
                }
            }
        }
    }
    
    // MARK: - Utilities
    func cleanup() {
        interactingTask.cancel()
        timerService.stop()
        cachedPlayerLayer = nil
    }
    
    func setAspectFill(_ fill: Bool) {
        if cachedPlayerLayer == nil || cachedPlayerLayer?.player !== player {
            cachedPlayerLayer = findPlayerLayer()
        }
        cachedPlayerLayer?.videoGravity = fill ? .resizeAspectFill : .resizeAspect
    }
    
    private func findPlayerLayer() -> AVPlayerLayer? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else {
            return nil
        }
        return findLayer(in: window.layer)
    }
    
    private func findLayer(in layer: CALayer) -> AVPlayerLayer? {
        if let playerLayer = layer as? AVPlayerLayer, playerLayer.player === player {
            return playerLayer
        }
        for sublayer in layer.sublayers ?? [] {
            if let found = findLayer(in: sublayer) {
                return found
            }
        }
        return nil
    }
}
