//
//  FSVideoPlayerViewModel.swift
//  FSVideoPlayer
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
final class FSVideoPlayerViewModel: ObservableObject {
    
    // MARK: - Timeouts Configuration
    
    enum HideTimeout: TimeInterval {
        case playPause = 0.5
        case interaction = 3.0
    }
    
    // MARK: - Properties
    
    let playerController: FSPlayerController
    
    @Published private(set) var isSliderInteracting = false
    @Published var showControls = true
    
    private var timerService = HideControlsTimerService()
    private var cachedPlayerLayer: AVPlayerLayer?

    // MARK: - Init
    
    init(playerController: FSPlayerController) {
        self.playerController = playerController
        
        timerService.configure { [weak self] in
            self?.showControls = false
        }
    }

    // MARK: - Player Control
    
    func startPlaying() {
        playerController.play()
        scheduleHide(after: .interaction)
    }
    
    func togglePlayPause() {
        playerController.togglePlayPause()
        scheduleHide(after: .playPause)
    }
    
    // MARK: - Skip Controls
    
    func skipForward(sliderViewModel: FSVideoSliderViewModel) {
        sliderViewModel.skipForward()
        scheduleHide(after: .interaction)
    }
    
    func skipBackward(sliderViewModel: FSVideoSliderViewModel) {
        sliderViewModel.skipBackward()
        scheduleHide(after: .interaction)
    }
    
    // MARK: - Slider Interaction
    
    func sliderInteractionStarted() {
        isSliderInteracting = true
        timerService.stop()
    }
    
    func sliderInteractionEnded() {
        isSliderInteracting = false
        scheduleHide(after: .interaction)
    }
    
    // MARK: - Controls Visibility
    
    func toggleControlsVisibility() {
        showControls = true
        if !isSliderInteracting {
            scheduleHide(after: .interaction)
        }
    }
    
    private func scheduleHide(after timeout: HideTimeout) {
        showControls = true
        timerService.start(timeout: timeout.rawValue)
    }
    
    // MARK: - Aspect Ratio
    
    func setAspectFill(_ fill: Bool) {
        if cachedPlayerLayer == nil || cachedPlayerLayer?.player !== playerController.player {
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
        if let playerLayer = layer as? AVPlayerLayer, playerLayer.player === playerController.player {
            return playerLayer
        }
        for sublayer in layer.sublayers ?? [] {
            if let found = findLayer(in: sublayer) {
                return found
            }
        }
        return nil
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        timerService.stop()
        cachedPlayerLayer = nil
    }
}
