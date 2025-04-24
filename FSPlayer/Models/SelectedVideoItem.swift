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
        if playlist.lowercased() == "default" {
            return video.hlsURL
        }

        guard let basePath = video.hlsURL.components(separatedBy: "/").dropLast().joined(separator: "/").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return video.hlsURL
        }

        return "\(basePath)/\(playlist)"
    }
}
