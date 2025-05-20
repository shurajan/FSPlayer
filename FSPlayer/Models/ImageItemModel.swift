//
//  NsfwItemModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//

import Foundation

struct ImageItemModel: Identifiable {
    let id = UUID()
    let filename: String
    let urlPath: String
}

extension ImageItemModel {
    static func models(from filenames: [String], basePath: String) -> [ImageItemModel] {
        filenames.map {
            let fullPath = basePath.hasSuffix("/") ? basePath + $0 : basePath + "/" + $0
            return ImageItemModel(filename: $0, urlPath: fullPath)
        }
    }
}
