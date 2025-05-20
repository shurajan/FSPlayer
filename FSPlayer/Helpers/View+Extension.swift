//
//  View+Extension.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
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

extension View {
    @ViewBuilder
    func withPerformanceOverlay() -> some View {
        self.modifier(PerformanceOverlayWrapper())
    }
}

private struct PerformanceOverlayWrapper: ViewModifier {
    @EnvironmentObject private var globalSettings: GlobalSettings

    func body(content: Content) -> some View {
        if globalSettings.isPerformanceOverlayEnabled {
            content.performanceOverlay()
        } else {
            content
        }
    }
}
