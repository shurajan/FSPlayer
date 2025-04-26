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
    private var seekTask: Task<Void, Never>?
    private var finalSeekTask: Task<Void, Never>?
    private var cachedPlayerLayer: AVPlayerLayer?

    private var lastSeekUpdate: Date = .now
    private var lastSeekValue: Double = 0

    @Published var isPlaying = false
    @Published var showControls = true
    @Published var isInteracting = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1

    // MARK: - Initialization

    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }

    private func setupObservers() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.3, preferredTimescale: 600),
            queue: .main,
            using: { [weak self] time in
                guard let self else { return }
                Task { @MainActor in
                    self.currentTime = time.seconds
                }
            }
        )

        if let item = player.currentItem {
            item.publisher(for: \.duration)
                .sink { [weak self] duration in
                    guard let self else { return }
                    let seconds = duration.seconds
                    self.duration = (seconds.isFinite && !seconds.isNaN && seconds > 0) ? seconds : 1
                }
                .store(in: &cancellables)

            item.publisher(for: \.status)
                .sink { status in
                    switch status {
                    case .readyToPlay:
                        print("✅ Player ready to play")
                    case .failed:
                        print("❌ Player failed: \(item.error?.localizedDescription ?? "Unknown error")")
                    case .unknown:
                        print("❓ Player status unknown")
                    @unknown default:
                        break
                    }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Public Methods

    func startPlaying() {
        player.play()
        isPlaying = true
        scheduleHideControls()
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        scheduleHideControls()
    }

    func toggleControls() {
        withAnimation {
            showControls = true
        }
        restartHideControls()
    }

    func setAspectFill(_ fill: Bool) {
        if cachedPlayerLayer == nil || cachedPlayerLayer?.player !== player {
            cachedPlayerLayer = findPlayerLayer()
        }
        cachedPlayerLayer?.videoGravity = fill ? .resizeAspectFill : .resizeAspect
    }

    func startInteraction() {
        isInteracting = true
        cancelHideControls()
        showControlsManually()
        pauseIfNeeded()
    }

    func endInteraction() {
        isInteracting = false
        restartHideControls()
        resumeIfNeeded()
    }

    func seek(to time: Double) {
        seekTask?.cancel()
        seekTask = Task { @MainActor in
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            await player.seek(
                to: cmTime,
                toleranceBefore: CMTime(seconds: 0.3, preferredTimescale: 600),
                toleranceAfter: CMTime(seconds: 0.3, preferredTimescale: 600)
            )
            currentTime = time
        }
    }

    func seekConsideringSpeed(to newValue: Double) {
        let now = Date()
        let deltaSeconds = now.timeIntervalSince(lastSeekUpdate)
        let deltaPosition = abs(newValue - lastSeekValue)
        let speed = deltaPosition / max(deltaSeconds, 0.001) // безопасное деление

        lastSeekUpdate = now
        lastSeekValue = newValue

        if speed > 60 {
            // very fast scroll
            scheduleFinalAccurateSeek(to: newValue)
            return
        }

        if speed < 2 {
            // slow
            seek(to: newValue)
        } else if deltaPosition > 10 {
            // normal speed
            seek(to: newValue)
        }

        // В любом случае запланировать финальный точный догоняющий seek
        scheduleFinalAccurateSeek(to: newValue)
    }

    func skipForward() {
        let current = player.currentTime()
        let newTime = CMTimeGetSeconds(current) + 10
        let clampedTime = min(newTime, duration)
        seek(to: clampedTime)
    }

    func skipBackward() {
        let current = player.currentTime()
        let newTime = CMTimeGetSeconds(current) - 10
        let clampedTime = max(newTime, 0)
        seek(to: clampedTime)
    }

    func cancelHideControls() {
        hideControlsTask?.cancel()
    }

    func restartHideControls() {
        hideControlsTask?.cancel()
        scheduleHideControls()
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

    func cleanup() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        cancellables.forEach { $0.cancel() }
        hideControlsTask?.cancel()
        seekTask?.cancel()
        finalSeekTask?.cancel()
        cachedPlayerLayer = nil
    }

    // MARK: - Private Methods

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                guard let self else { return }
                if !self.isInteracting {
                    withAnimation {
                        self.showControls = false
                    }
                }
                self.hideControlsTask = nil
            }
        }
    }

    private func scheduleFinalAccurateSeek(to time: Double) {
        finalSeekTask?.cancel()
        finalSeekTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms пауза
            await MainActor.run {
                guard let self else { return }
                self.seek(to: time)
            }
        }
    }

    private func showControlsManually() {
        withAnimation {
            showControls = true
        }
    }

    private func pauseIfNeeded() {
        if isPlaying {
            player.pause()
        }
    }

    private func resumeIfNeeded() {
        if isPlaying {
            player.play()
        }
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
