//
//  FSVideoPlayerSlider.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 28.04.2025.
//

import SwiftUI
import AVKit

struct FSVideoSlider: View {
    @StateObject private var viewModel: FSVideoSliderViewModel
    @Binding var isInteracting: Bool

    init(player: AVPlayer, isInteracting: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: FSVideoSliderViewModel(player: player))
        self._isInteracting = isInteracting
    }
    
    var body: some View {
        VStack {
            Slider(
                value: $viewModel.sliderValue,
                in: 0...viewModel.duration,
                onEditingChanged: { editing in                    
                    if editing {
                        viewModel.startSliderInteraction()
                    } else {
                        viewModel.updateSliderValue(viewModel.sliderValue)
                        viewModel.endSliderInteraction()
                    }
                    isInteracting = editing
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
