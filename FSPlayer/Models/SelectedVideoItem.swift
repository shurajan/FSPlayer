//
//  SelectedVideoModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

struct SelectedVideoItem: Identifiable {
    var id: String {
        playlist + "_" + video.id
    }
    let video: VideoItemModel
    let playlist: String
    
    func hlsPathWithPlaylist() -> String {
        return "\(video.hlsURL)\(playlist)"
    }
}
