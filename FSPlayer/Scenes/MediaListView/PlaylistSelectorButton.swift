//
//  PlaylistSelectorButton.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 25.04.2025.
//

import SwiftUI

struct PlaylistSelectorButton: View {
    @Binding var selected: PlaylistItemModel?
    let playlists: [PlaylistItemModel]

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                Text(selected?.shortName ?? "Select playlist")
                    .lineLimit(1)
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
        }
        .sheet(isPresented: $showSheet) {
            PlaylistSelectionView(
                selected: $selected,
                playlists: playlists,
                dismiss: { showSheet = false }
            )
        }
    }
}
