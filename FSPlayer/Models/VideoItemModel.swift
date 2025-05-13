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
        case createdAt
        case duration
        case resolution
        case sizeMB
        case segmentCount
        case avgSegmentDuration
    }
}
