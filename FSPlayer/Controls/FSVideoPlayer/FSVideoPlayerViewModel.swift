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
    private var debouncedSeekTask: Task<Void, Never>?
    private var cachedPlayerLayer: AVPlayerLayer?

    @Published var isPlaying = false
    @Published var showControls = true
    @Published var isInteracting = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var sliderValue: Double = 0
    
    // Добавим настройки для быстрого просмотра
    private let seekDebounceDelay: UInt64 = 30_000_000 // 30ms вместо 50ms для более быстрого отклика

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
                if !self.isInteracting {
                    self.currentTime = time.seconds
                    self.sliderValue = time.seconds
                }
            }
        }

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

    // MARK: - Public Controls
    
    func pause() {
        player.pause()
        isPlaying = false
    }

    func play() {
        player.play()
        isPlaying = true
    }

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

    func startInteraction() {
        isInteracting = true
        cancelHideControls()
        showControlsManually()
    }

    func endInteraction() {
        isInteracting = false
        restartHideControls()
    }

    func seekImmediately(to time: Double) {
        seekTask?.cancel()
        seekTask = Task { @MainActor in
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            await player.seek(
                to: cmTime,
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
            currentTime = time
        }
    }

    func seekDebounced(to time: Double) {
        debouncedSeekTask?.cancel()
        debouncedSeekTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.seekDebounceDelay ?? 30_000_000) // 30ms пауза для более быстрого отклика
            await MainActor.run {
                guard let self else { return }
                // Используем более быстрый метод поиска для скраббинга
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                self.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
                self.currentTime = time
            }
        }
    }

    func skipForward() {
        let current = player.currentTime()
        let newTime = CMTimeGetSeconds(current) + 10
        let clampedTime = min(newTime, duration)
        seekImmediately(to: clampedTime)
    }

    func skipBackward() {
        let current = player.currentTime()
        let newTime = CMTimeGetSeconds(current) - 10
        let clampedTime = max(newTime, 0)
        seekImmediately(to: clampedTime)
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
        debouncedSeekTask?.cancel()
        cachedPlayerLayer = nil
    }

    func setAspectFill(_ fill: Bool) {
        if cachedPlayerLayer == nil || cachedPlayerLayer?.player !== player {
            cachedPlayerLayer = findPlayerLayer()
        }
        cachedPlayerLayer?.videoGravity = fill ? .resizeAspectFill : .resizeAspect
    }

    // MARK: - Private Helpers

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
