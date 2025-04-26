//
//  PerformanceOverlayView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import SwiftUI

#if DEBUG
struct PerformanceOverlayView: View {
    @ObservedObject private var monitor = PerformanceMonitor.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FPS: \(monitor.fps)")
            Text(String(format: "CPU: %.1f%%", monitor.cpu))
            Text(String(format: "Memory: %.1f MB", monitor.memory))
        }
        .font(.caption2)
        .padding(8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
        .foregroundColor(.green)
        .padding()
        .onAppear {
            monitor.start()
        }
        .onDisappear {
            monitor.stop()
        }
    }
}
#endif
