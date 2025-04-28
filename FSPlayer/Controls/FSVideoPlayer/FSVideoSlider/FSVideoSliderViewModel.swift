//
//  FSVideoPlayerSliderViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 28.04.2025.
//
import SwiftUI
import AVFoundation
import Combine

@MainActor
final class FSVideoSliderViewModel: ObservableObject {
    // MARK: - Properties
    let player: AVPlayer
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isJumping: Bool = false
    
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var sliderValue: Double = 0
    @Published var isSeeking = false
    
    // MARK: - Initialization
    
    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.cleanup()
        }
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
    }
    
    func endSliderInteraction() {
        isJumping = true
        isSeeking = false
    }
    
    func updateSliderValue(_ newValue: Double) {
        let clamped = max(0, min(newValue, duration))
        seekImmediately(to: clamped)
    }
    
    // MARK: - Skip Controls
    func skipForward() {
        updateSliderValue(sliderValue + 10)
    }
    
    func skipBackward() {
        updateSliderValue(sliderValue - 10)
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
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
}
