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
    let duration: Int?
    let resolution: String?
    let createdAt: String?
    let sizeMB: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hlsURL
        case duration
        case resolution
        case createdAt
        case sizeMB
    }
}
