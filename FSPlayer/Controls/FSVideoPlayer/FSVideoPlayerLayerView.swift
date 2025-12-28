//
//  FSVideoPlayerLayerView.swift
//  FSVideoPlayer
//

import SwiftUI
import AVFoundation

struct FSVideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    class PlayerUIView: UIView {
        var playerLayer: AVPlayerLayer

        init(player: AVPlayer) {
            playerLayer = AVPlayerLayer(player: player)
            super.init(frame: .zero)
            playerLayer.videoGravity = .resizeAspect
            layer.addSublayer(playerLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
