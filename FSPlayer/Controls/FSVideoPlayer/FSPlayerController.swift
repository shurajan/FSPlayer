//
//  FSPlayerController.swift
//  FSVideoPlayer
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class FSPlayerController: ObservableObject {
    let player: AVPlayer

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var errorMessage: String?

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // Seeks are coalesced: while one is in flight, only the latest
    // requested target is kept and executed when the current one finishes.
    private var isSeekInProgress = false
    private var pendingSeek: (time: CMTime, precise: Bool)?
    private var wasPlayingBeforeScrub = false

    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }

    // MARK: - Playback

    func play() {
        // At the end of the video AVPlayer ignores play(); rewind first so
        // the play button acts as "replay".
        if duration > 0, currentTime >= duration - 0.5 {
            seek(to: 0)
        }
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func skip(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    func seek(to seconds: Double, precise: Bool = true) {
        let upperBound = duration > 0 ? duration : seconds
        let clamped = max(0, min(seconds, upperBound))
        currentTime = clamped
        enqueueSeek(CMTime(seconds: clamped, preferredTimescale: 600), precise: precise)
    }

    // MARK: - Scrubbing

    func beginScrubbing() {
        wasPlayingBeforeScrub = player.timeControlStatus != .paused
        player.pause()
    }

    func scrub(to seconds: Double) {
        seek(to: seconds, precise: false)
    }

    func endScrubbing(at seconds: Double) {
        seek(to: seconds, precise: true)
        if wasPlayingBeforeScrub {
            player.play()
        }
    }

    // MARK: - Observers

    private func setupObservers() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, !self.isSeekInProgress else { return }
                self.currentTime = time.seconds
            }
        }

        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = status != .paused
            }
            .store(in: &cancellables)

        player.publisher(for: \.currentItem?.duration)
            .compactMap { $0?.seconds }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.duration = (seconds > 0 && seconds.isFinite) ? seconds : 0
            }
            .store(in: &cancellables)

        player.publisher(for: \.currentItem?.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self, status == .failed else { return }
                self.errorMessage = self.player.currentItem?.error?.localizedDescription
                    ?? "Failed to load video"
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: player.currentItem
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.errorMessage = error?.localizedDescription ?? "Playback failed"
        }
        .store(in: &cancellables)
    }

    // MARK: - Coalesced seeking

    private func enqueueSeek(_ time: CMTime, precise: Bool) {
        pendingSeek = (time, precise)
        if !isSeekInProgress {
            performNextSeek()
        }
    }

    private func performNextSeek() {
        guard let request = pendingSeek else { return }
        pendingSeek = nil
        isSeekInProgress = true

        let tolerance: CMTime = request.precise ? .zero : .positiveInfinity
        player.seek(to: request.time, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSeekInProgress = false
                self.performNextSeek()
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.removeAll()
        pendingSeek = nil
    }
}
