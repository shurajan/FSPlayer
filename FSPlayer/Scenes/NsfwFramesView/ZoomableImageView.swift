//
//  ZoomableImageView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//
import SwiftUI

struct ZoomableImageView: View {
    @Binding var navigationPath: [NavigationDestination]
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale
                    })
        }
    }
}
