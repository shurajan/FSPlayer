//
//  FSPlayerController.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 19.05.2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class FSPlayerController: ObservableObject {
    let player: AVPlayer

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 1

    // We'll use a different approach since nonisolated can't be used on mutable properties
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }

    func play() {
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func setupObservers() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
            }
        }

        player.publisher(for: \.currentItem?.duration)
            .compactMap { $0?.seconds }
            .receive(on: RunLoop.main)
            .sink { [weak self] seconds in
                self?.duration = (seconds > 0 && seconds.isFinite) ? seconds : 1
            }
            .store(in: &cancellables)
    }

    // Add a cleanup method that should be called before deinit
    func prepareForDeinit() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.forEach { $0.cancel() }
    }
    
    func cleanup() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.forEach { $0.cancel() }
    }
}
