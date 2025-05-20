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
    let keyframesURL: String?
    let nsfwframesURL: String?
    let createdAt: String?
    let duration: Int
    let resolution: String?
    let sizeMB: Int?
    let segmentCount: Int?
    let avgSegmentDuration: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hlsURL
        case keyframesURL
        case nsfwframesURL
        case createdAt
        case duration
        case resolution
        case sizeMB
        case segmentCount
        case avgSegmentDuration
    }
    
    func formatDuration() -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let secs = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    func formatSize() -> String {
        let size = Double(sizeMB ?? 0)

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

extension VideoItemModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VideoItemModel, rhs: VideoItemModel) -> Bool {
        lhs.id == rhs.id
    }
}
