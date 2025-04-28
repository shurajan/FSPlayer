//
//  FSVideoPlayerViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//
import SwiftUI
import AVFoundation
import Combine

@MainActor
final class FSVideoPlayerViewModel: ObservableObject {
    // MARK: - Properties
    
    let player: AVPlayer
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var hideControlsTask: Task<Void, Never>?
    private var cachedPlayerLayer: AVPlayerLayer?
    private var isJumping: Bool = false
    
    // Публичные свойства
    @Published var isPlaying = false
    @Published var showControls = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var sliderValue: Double = 0
    @Published var isSeeking = false
    
    // MARK: - Initialization
    
    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }
    
    private func setupObservers() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.3, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                if !self.isSeeking {
                    let seconds = time.seconds
                    self.currentTime = seconds
                    if isJumping {
                        isJumping = false
                        return
                    }
                    self.sliderValue = seconds
                }
            }
        }
        
        player.currentItem?.publisher(for: \.duration)
            .sink { [weak self] duration in
                guard let self else { return }
                let seconds = duration.seconds
                self.duration = (seconds.isFinite && !seconds.isNaN && seconds > 0) ? seconds : 1
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playback Controls
    
    func startPlaying() {
        player.play()
        isPlaying = true
        showControls = false
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
        resetHideTimer()
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    func seekImmediately(to time: Double) {
        Task { @MainActor in
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            await player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
            self.currentTime = time
            self.sliderValue = time
        }
    }
    
    // MARK: - Slider Interaction
    
    func startSliderInteraction() {
        isSeeking = true
        cancelHideTimer()
    }
    
    func endSliderInteraction() {
        isJumping = true
        isSeeking = false
        scheduleHideTimer()
    }
    
    func updateSliderValue(_ newValue: Double) {
        let clamped = max(0, min(newValue, duration))
        seekImmediately(to: clamped)
        
        if isSeeking {
            resetHideTimer()
        }
    }
    
    // MARK: - Skip Controls
    
    func skipForward() {
        updateSliderValue(sliderValue + 10)
        resetHideTimer()
    }
    
    func skipBackward() {
        updateSliderValue(sliderValue - 10)
        resetHideTimer()
    }
    
    // MARK: - UI Controls
    
    func toggleControls() {
        withAnimation {
            showControls = true
        }
        resetHideTimer()
    }
    
    // Единый метод для сброса таймера
    func resetHideTimer() {
        if !isSeeking {
            cancelHideTimer()
            scheduleHideTimer()
        }
    }
    
    private func scheduleHideTimer() {
        cancelHideTimer()
        
        hideControlsTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(3))
                
                await MainActor.run {
                    guard let self = self, !self.isSeeking else { return }
                    
                    withAnimation {
                        self.showControls = false
                    }
                }
            } catch {
            }
        }
    }
    
    // Отменяет таймер скрытия
    private func cancelHideTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
    }
    
    // MARK: - Utilities
    
    func formattedTime(_ time: Double) -> String {
        let safeTime = time.isFinite && !time.isNaN ? time : 0
        let totalSeconds = Int(safeTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.forEach { $0.cancel() }
        hideControlsTask?.cancel()
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
