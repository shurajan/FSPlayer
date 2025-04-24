//
//  PlaylistPicker.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//


import SwiftUI

struct PlaylistPicker: View {
    @Binding var selectedPlaylist: String
    let playlists: [String]

    private var allPlaylists: [String] {
        ["default"] + playlists
    }

    var body: some View {
        if playlists.isEmpty {
            Label("Default", systemImage: "list.bullet")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
        } else {
            Picker("", selection: $selectedPlaylist) {
                ForEach(allPlaylists, id: \.self) { playlist in
                    Text(playlist.capitalized).tag(playlist)
                }
            }
            .labelsHidden() 
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
            .frame(maxWidth: 200)
        }
    }
}
