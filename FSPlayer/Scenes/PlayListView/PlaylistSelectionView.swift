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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(playlists.indices, id: \.self) { index in
                        PlaylistRowView(
                            playlist: playlists[index],
                            onSelect: {
                                selected = playlists[index]
                                dismiss()
                            },
                            onDelete: {
                                print("Delete \(playlists[index].shortName)")
                            },
                            onTrim: {
                                print("Trim \(playlists[index].shortName)")
                            }
                        )
                        if index < playlists.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle("Select Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.dynamicColor(light: Color.white, dark: Color.black))
                    }
                }
            }
        }
    }
}
