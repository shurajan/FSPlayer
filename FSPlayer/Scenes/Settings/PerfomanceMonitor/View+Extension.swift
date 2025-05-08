//
//  View+Extension.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func performanceOverlay() -> some View {
        #if DEBUG
        self.overlay(alignment: .topTrailing) {
            PerformanceOverlayView()
        }
        #else
        self
        #endif
    }
}
