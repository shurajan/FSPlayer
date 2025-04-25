//
//  PlaylistFormatters.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 25.04.2025.
//

import Foundation

enum PlaylistFormatters {
    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    static func formatSize(_ sizeInMB: Int) -> String {
        let size = Double(sizeInMB)

        switch size {
        case 0..<1:
            return "<1 MB"
        case 1..<1024:
            return String(format: "%.0f MB", size)
        case 1024..<10_240:
            return String(format: "%.1f GB", size / 1024)
        default:
            return String(format: "%.0f GB", size / 1024)
        }
    }
}
