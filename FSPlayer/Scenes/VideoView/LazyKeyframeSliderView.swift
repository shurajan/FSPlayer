//
//  LazyKeyframeSliderView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 13.05.2025.
//

import SwiftUI

struct LazyKeyframeSliderView: View {
    let segmentCount: Int
    let keyframesURL: String
    let thumbnailHeight: CGFloat
    let onTap: (Int) -> Void
    @EnvironmentObject private var session: SessionStorage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 4) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    KeyframeThumbnailView(
                        index: index,
                        keyframesURL: keyframesURL,
                        height: thumbnailHeight,
                        onTap: onTap
                    )
                    .environmentObject(session)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
