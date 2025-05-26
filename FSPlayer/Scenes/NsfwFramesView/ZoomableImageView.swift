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

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size

            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, lastScale * value)
                                    updateOffset(containerSize: containerSize)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    updateOffset(containerSize: containerSize)
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    updateOffset(containerSize: containerSize)
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
            }
        }
    }

    // Ограничиваем offset по краям изображения
    private func updateOffset(containerSize: CGSize) {
        // Размер изображения при текущем масштабе
        let imageWidth = containerSize.width * scale
        let imageHeight = containerSize.height * scale

        // Границы смещения по X и Y
        let maxX = max(0, (imageWidth - containerSize.width) / 2)
        let maxY = max(0, (imageHeight - containerSize.height) / 2)

        // Ограничиваем offset
        offset.width = min(max(offset.width, -maxX), maxX)
        offset.height = min(max(offset.height, -maxY), maxY)
    }
}
