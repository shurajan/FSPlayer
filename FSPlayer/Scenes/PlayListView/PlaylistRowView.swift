//
//  PlaylistRowView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 25.04.2025.
//

import SwiftUI

struct PlaylistRowView: View {
    let playlist: PlaylistItemModel
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onTrim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.shortName)
                        .font(.headline)

                    HStack(spacing: 12) {
                        if let res = playlist.resolution {
                            Label(res, systemImage: "rectangle.3.offgrid")
                        }

                        if playlist.duration > 0 {
                            Label(PlaylistFormatters.formatDuration(playlist.duration), systemImage: "clock")
                        }

                        if let size = playlist.sizeMB {
                            Label(PlaylistFormatters.formatSize(size), systemImage: "externaldrive")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    
                    HStack(spacing: 16) {
                        Button(role: .destructive, action: onDelete) {
                            Label("Удалить", systemImage: "trash")
                        }

                        if playlist.duration > 0 {
                            Button(action: onTrim) {
                                Label("Обрезать", systemImage: "scissors")
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding(.leading, 4)
                    
                }

                Spacer()

                Button(action: onSelect) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
