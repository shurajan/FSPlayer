//
//  FileItem.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//
import Foundation

struct VideoItemModel: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let hlsURL: String
    let createdAt: String?
    let playlists: [PlaylistItemModel]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hlsURL
        case createdAt
        case playlists
    }
}

struct PlaylistItemModel: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let name: String
    let duration: Int
    let resolution: String?
    let sizeMB: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case duration
        case resolution
        case sizeMB
    }
    
    var shortName: String {
        String(name.split(separator: ".").first ?? "")
    }
}
