//
//  PlaylistPicker.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//
import SwiftUI

struct PlaylistSelectionView: View {
    @Binding var selected: PlaylistItemModel?
    let playlists: [PlaylistItemModel]
    let dismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(playlists) { playlist in
                    Button(action: {
                        selected = playlist
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.shortName)
                                .font(.headline)

                            HStack(spacing: 12) {
                                if let res = playlist.resolution {
                                    Label(res, systemImage: "rectangle.3.offgrid")
                                }

                                Label(formatDuration(playlist.duration), systemImage: "clock")

                                if let size = playlist.sizeMB {
                                    Label(formatSize(size), systemImage: "externaldrive")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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

    private func formatSize(_ sizeInMB: Int) -> String {
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
