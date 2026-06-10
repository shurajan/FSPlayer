//
//  FSVideoScrubber.swift
//  FSVideoPlayer
//

import SwiftUI

struct FSVideoScrubber: View {

    let duration: Double
    let time: Double
    var onScrubStarted: () -> Void
    var onScrubChanged: (Double) -> Void
    var onScrubEnded: (Double) -> Void

    @State private var isDragging = false

    private var trackHeight: CGFloat { isDragging ? 6 : 3 }
    private var thumbSize: CGFloat { isDragging ? 18 : 12 }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progress = duration > 0 ? min(max(time / duration, 0), 1) : 0
            let thumbX = progress * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(Color.red)
                    .frame(width: thumbX, height: trackHeight)

                Circle()
                    .fill(Color.red)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onScrubStarted()
                        }
                        onScrubChanged(timeForLocation(value.location.x, width: width))
                    }
                    .onEnded { value in
                        isDragging = false
                        onScrubEnded(timeForLocation(value.location.x, width: width))
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: isDragging)
        }
        .frame(height: 36)
    }

    private func timeForLocation(_ x: CGFloat, width: CGFloat) -> Double {
        guard width > 0, duration > 0 else { return 0 }
        let fraction = min(max(x / width, 0), 1)
        return Double(fraction) * duration
    }
}
