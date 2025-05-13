//
//  VideoItemView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

import SwiftUI

struct VideoItemView: View {
    let video: VideoItemModel
    let onSelect: (VideoItemModel) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(video.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(alignment:.center, spacing: 12 ) {
                    if let created = video.createdAt,
                       let date = ISO8601DateFormatter().date(from: created) {
                        Label(date.formatted(date: .numeric, time: .shortened), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    
                    Label(PlaylistFormatters.formatDuration( video.duration), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label(PlaylistFormatters.formatSize(video.sizeMB ?? 0), systemImage: "externaldrive")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
            }
            .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)



            Button(action: {
                    onSelect(video)
            }) {
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(16)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    
    }
}
