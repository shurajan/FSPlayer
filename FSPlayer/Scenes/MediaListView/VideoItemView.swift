//
//  VideoItemView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

import SwiftUI

struct VideoItemView: View {
    let file: VideoItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Название + разрешение
            HStack {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if let resolution = file.resolution {
                    Text(resolution)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            // Длительность
            if let duration = file.duration {
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Размер и дата
            HStack(spacing: 16) {
                if let size = file.sizeMB {
                    Label("\(formatSize(size))", systemImage: "externaldrive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let created = file.createdAt,
                   let date = ISO8601DateFormatter().date(from: created) {
                    Label(date.formatted(date: .numeric, time: .shortened),
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func formatSize(_ sizeInMB: Int) -> String {
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
