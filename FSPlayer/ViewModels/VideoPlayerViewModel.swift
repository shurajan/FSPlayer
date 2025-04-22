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

    @Published private(set) var player: AVPlayer?
    @Published var errorMessage: String?

    private let file: FileItem
    private unowned let session: SessionViewModel

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private let saveInterval: CMTime = .init(seconds: 5, preferredTimescale: 1)

    init(file: FileItem, session: SessionViewModel) {
        self.file    = file
        self.session = session
        configurePlayer()
    }

    private func configurePlayer() {
        guard
            let host  = session.host,
            let token = session.token
        else {
            errorMessage = "Токен или host не заданы"
            return
        }

        let urlString = "http://\(host)/files/\(file.name)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Неверный URL: \(urlString)"
            return
        }

        let httpHeaders = ["Authorization": "Bearer \(token)"]
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders]

        let asset  = AVURLAsset(url: url, options: options)
        let item   = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.allowsExternalPlayback = false

        let savedSeconds = StorageService.shared.loadVideoPosition(for: file.id.uuidString) ?? 0.0
        if savedSeconds > 0 {
            let savedTime = CMTime(seconds: savedSeconds, preferredTimescale: 600)
            player.seek(to: savedTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        addTimeObserver(to: player)

        self.player = player
    }

    private func addTimeObserver(to player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(forInterval: saveInterval,
                                                      queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                self.savePosition(time)
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime,
                                             object: player.currentItem)
            .sink { [weak self] _ in self?.resetPosition() }
            .store(in: &cancellables)
    }

    private func savePosition(_ time: CMTime) {
        guard time.isNumeric else { return }
        let seconds = time.seconds

        if let duration = player?.currentItem?.duration.seconds,
           duration.isFinite,
           duration - seconds < 3 {
            resetPosition()
        } else {
            StorageService.shared.saveVideoPosition(seconds, for: file.id.uuidString)
        }
    }

    private func resetPosition() {
        StorageService.shared.clearVideoPosition(for: file.id.uuidString)
    }

    func play() {
        player?.play()
    }

    func cleanup() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.replaceCurrentItem(with: nil)
        player = nil
        cancellables.removeAll()
    }
}
