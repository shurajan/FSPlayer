//
//  MediaListViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI

@MainActor
final class VideoListViewModel: ObservableObject {

    @Published var files: [VideoItemModel]            = []
    @Published var errorMessage: String?        = nil
    @Published var isLoading                    = false
    @Published var sortOption: SortOption       = .name
    @Published var fileToDelete: VideoItemModel?      = nil
    @Published var showDeleteConfirmation       = false
    @Published var selectedFile: VideoItemModel?      = nil

    // MARK: ‑ Sorting
    enum SortOption: String, CaseIterable, Identifiable {
        case name       = "Name (A–Z)"
        case size       = "Size (Descending)"
        case duration   = "Duration (Descending)"
        case createdAt  = "Newest First"

        var id: String { rawValue }
    }

    var sortedFiles: [VideoItemModel] {
        switch sortOption {
        case .name:
            return files.sorted { $0.name.lowercased() < $1.name.lowercased() }

        case .size:
            return files.sorted {
                ($0.sizeMB ?? 0) > ($1.sizeMB ?? 0)
            }

        case .duration:
            return files.sorted {
                ($0.duration ?? 0) > ($1.duration ?? 0)
            }

        case .createdAt:
            return files.sorted {
                // Сначала пытаемся парсить, потом сравниваем
                let date0 = ISO8601DateFormatter().date(from: $0.createdAt ?? "") ?? .distantPast
                let date1 = ISO8601DateFormatter().date(from: $1.createdAt ?? "") ?? .distantPast
                return date0 > date1
            }
        }
    }

    // MARK: ‑ Public API (вызывается View)

    func loadFiles(host: String, token: String) async {
        errorMessage = nil
        isLoading    = true
        defer { isLoading = false }

        switch await VideoService.shared.fetchFiles(host: host, token: token) {
        case .success(let fetched):
            files = fetched
        case .failure(let error):
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unknown error"
        }
    }

    func delete(_ file: VideoItemModel, host: String, token: String) async {
        switch await VideoService.shared.deleteFile(name: file.name, host: host, token: token) {
        case .success:
            files.removeAll { $0 == file }
        case .failure(let error):
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }
}
