//
//  FSVideoPlayerLayerView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//
import SwiftUI
import AVKit

struct FSVideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }
    }
}
