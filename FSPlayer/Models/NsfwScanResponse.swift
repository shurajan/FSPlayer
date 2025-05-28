//
//  NsfwScanResponse.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 27.05.2025.
//
import Foundation

struct NsfwScanResponse: Decodable {
    let message: String
    let taskId: String

    enum CodingKeys: String, CodingKey {
        case message
        case taskId = "task_id"
    }
}
