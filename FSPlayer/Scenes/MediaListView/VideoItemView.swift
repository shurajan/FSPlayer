//
//  VideoItemView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

import SwiftUI

struct VideoItemView: View {
    let video: VideoItemModel
    let onSelect: (VideoItemModel, String) -> Void
    @State private var selectedPlaylist: String = "default"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let duration = video.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let resolution = video.resolution {
                            Text(resolution)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(5)
                        }
                        
                        if let size = video.sizeMB {
                            Label("\(formatSize(size))", systemImage: "externaldrive")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let created = video.createdAt,
                           let date = ISO8601DateFormatter().date(from: created) {
                            Label(date.formatted(date: .numeric, time: .shortened),
                                  systemImage: "calendar")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()

                HStack(spacing: 12) {
                    PlaylistPicker(
                        selectedPlaylist: $selectedPlaylist,
                        playlists: video.clips ?? []
                    )
                    .font(.caption)
                    
                    Button(action: {
                        onSelect(video, selectedPlaylist)
                    }) {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(16)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
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
