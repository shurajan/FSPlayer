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
    let playerController: FSPlayerController

    private var cancellables = Set<AnyCancellable>()
    private var seekTimer: AnyCancellable?
    private var isJumping: Bool = false

    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var sliderValue: Double = 0
    @Published var isSeeking = false

    init(playerController: FSPlayerController) {
        self.playerController = playerController
        setupObservers()
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.cleanup()
        }
    }

    private func setupObservers() {
        playerController.$currentTime
            .sink { [weak self] time in
                guard let self else { return }
                if !self.isSeeking {
                    self.currentTime = time
                    if self.isJumping {
                        self.isJumping = false
                        return
                    }
                    self.sliderValue = time
                }
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

    func seekImmediately(to time: Double) {
        Task { @MainActor in
            playerController.seek(to: time)
            self.currentTime = time
            self.sliderValue = time
        }
    }

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

    func skipForward() {
        updateSliderValue(sliderValue + 10)
    }

    func skipBackward() {
        updateSliderValue(sliderValue - 10)
    }

    func cleanup() {
        seekTimer?.cancel()
        seekTimer = nil

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

    private func updateFrameDuringSeeking() {
        let time = sliderValue
        playerController.seek(to: time)
        playerController.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.isSeeking {
                self.playerController.pause()
            }
        }
    }
}
