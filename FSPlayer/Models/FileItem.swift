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
    let hlsURL: String

    enum CodingKeys: String, CodingKey {
        case id, name, hlsURL
    }
}
