//
//  SelectedVideoModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

struct SelectedVideoItem: Identifiable {
    var id: String {
        video.id + "_" + playlist.id
    }
    let video: VideoItemModel
    let playlist: PlaylistItemModel
    
    func hlsPathWithPlaylist() -> String {
        return "\(video.hlsURL)\(playlist.name)"
    }
}
