//
//  FSVideoSliderViewModel.swift
//  FSVideoPlayer
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
final class FSVideoSliderViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let playerController: FSPlayerController

    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var sliderValue: Double = 0
    @Published private(set) var isSeeking = false

    private var cancellables = Set<AnyCancellable>()
    private var seekTimer: AnyCancellable?
    private var isJumping = false

    // MARK: - Init
    
    init(playerController: FSPlayerController) {
        self.playerController = playerController
        setupObservers()
    }

    // MARK: - Setup
    
    private func setupObservers() {
        playerController.$currentTime
            .sink { [weak self] time in
                guard let self, !self.isSeeking else { return }
                self.currentTime = time
                if self.isJumping {
                    self.isJumping = false
                    return
                }
                self.sliderValue = time
            }
            .store(in: &cancellables)

        playerController.$duration
            .assign(to: &$duration)

        seekTimer = Timer
            .publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isSeeking else { return }
                self.updateFrameDuringSeeking()
            }
    }
    
    // MARK: - Seeking
    
    func seekImmediately(to time: Double) {
        let clamped = max(0, min(time, duration))
        playerController.seek(to: clamped)
        currentTime = clamped
        sliderValue = clamped
    }

    func startSliderInteraction() {
        isSeeking = true
    }

    func endSliderInteraction() {
        isJumping = true
        isSeeking = false
    }

    func updateSliderValue(_ newValue: Double) {
        seekImmediately(to: newValue)
    }
    
    // MARK: - Skip
    
    func skipForward() {
        updateSliderValue(sliderValue + 10)
    }

    func skipBackward() {
        updateSliderValue(sliderValue - 10)
    }
    
    // MARK: - Time Formatting
    
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
    
    // MARK: - Private
    
    private func updateFrameDuringSeeking() {
        playerController.seek(to: sliderValue)
        playerController.play()

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard let self, self.isSeeking else { return }
            self.playerController.pause()
        }
    }

    // MARK: - Cleanup
    
    func cleanup() {
        seekTimer?.cancel()
        seekTimer = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
