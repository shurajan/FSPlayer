//
//  FileItem.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//
import Foundation

struct FileItem: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let size: Int
    let resolution: String?
    let duration: Int?
    let previewURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, size, resolution, duration, previewURL
    }

    var formattedDuration: String? {
        guard let duration else { return nil }

        if duration < 60 {
            return "⏱ \(duration)s"
        } else if duration < 3600 {
            let minutes = duration / 60
            let seconds = duration % 60
            return String(format: "⏱ %d:%02d", minutes, seconds)
        } else {
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            let seconds = duration % 60
            return String(format: "⏱ %d:%02d:%02d", hours, minutes, seconds)
        }
    }
}
