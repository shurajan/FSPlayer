//
//  FSVideoSlider.swift
//  FSVideoPlayer
//

import SwiftUI

struct FSVideoSlider: View {
    
    @ObservedObject var viewModel: FSVideoSliderViewModel
    
    var onInteractionStarted: (() -> Void)?
    var onInteractionEnded: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: $viewModel.sliderValue,
                in: 0...viewModel.duration,
                onEditingChanged: { editing in
                    if editing {
                        viewModel.startSliderInteraction()
                        onInteractionStarted?()
                    } else {
                        viewModel.updateSliderValue(viewModel.sliderValue)
                        viewModel.endSliderInteraction()
                        onInteractionEnded?()
                    }
                }
            )
            .accentColor(.red)
            
            timeLabels
        }
    }

    private var timeLabels: some View {
        HStack {
            Text(viewModel.formattedTime(viewModel.currentTime))
                .font(.caption)
                .foregroundColor(.white)

            Spacer()

            Text(viewModel.formattedTime(viewModel.duration))
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
