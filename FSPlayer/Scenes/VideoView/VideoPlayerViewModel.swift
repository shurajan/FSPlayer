//
//  VideoPlayerViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import AVKit
import AVFoundation
import Combine

@MainActor
final class VideoPlayerViewModel: ObservableObject {
    // MARK: – Published properties
    @Published private(set) var player: AVPlayer?
    @Published var errorMessage: String?

    // MARK: – Dependencies & state
    private let file: VideoItemModel
    private unowned let session: SessionStorage
    private var cancellables = Set<AnyCancellable>()

    // MARK: – Init
    init(file: VideoItemModel, session: SessionStorage) {
        self.file    = file
        self.session = session
        configurePlayer()
    }

    // MARK: – Configure AVPlayer & restore state
    private func configurePlayer() {
        guard
            let host  = session.host,
            let token = session.token
        else {
            errorMessage = "Missing host or token"
            return
        }

        let urlString = "http://\(host)\(file.hlsURL)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL: \(urlString)"
            return
        }

        // Inject Authorization header for HLS playlist + segments
        let headers  = ["Authorization": "Bearer \(token)"]
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": headers]

        let asset  = AVURLAsset(url: url, options: options)
        let item   = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.allowsExternalPlayback = false

        // Restore playback position
        if let savedSeconds = UserDataStorageService.shared.loadVideoPosition(for: file.id),
           savedSeconds > 0
        {
            let time = CMTime(seconds: savedSeconds, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        self.player = player

        // Save position when paused
        player.publisher(for: \.timeControlStatus)
            .filter { $0 == .paused }
            .sink { [weak self] _ in
                self?.saveCurrentPosition()
            }
            .store(in: &cancellables)

        // Reset position on end
        NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        .sink { [weak self] _ in
            self?.resetPosition()
        }
        .store(in: &cancellables)
    }

    // MARK: – Save / reset helpers
    private func saveCurrentPosition() {
        guard
            let player = player,
            let item = player.currentItem
        else { return }

        let seconds = player.currentTime().seconds
        guard seconds.isFinite else { return }

        let duration = item.duration.seconds
        if duration.isFinite, duration - seconds < 3 {
            resetPosition()
        } else {
            UserDataStorageService.shared.saveVideoPosition(seconds, for: file.id)
        }
    }

    private func resetPosition() {
        UserDataStorageService.shared.clearVideoPosition(for: file.id)
    }

    // MARK: – Public controls
    func play() {
        player?.play()
    }

    func cleanup() {
        player?.pause()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}
