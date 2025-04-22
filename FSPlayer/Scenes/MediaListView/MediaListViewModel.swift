//
//  MediaListViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 22.04.2025.
//

import SwiftUI

@MainActor
final class MediaListViewModel: ObservableObject {

    @Published var files: [FileItem]            = []
    @Published var errorMessage: String?        = nil
    @Published var isLoading                    = false
    @Published var sortOption: SortOption       = .name
    @Published var fileToDelete: FileItem?      = nil
    @Published var showDeleteConfirmation       = false
    @Published var selectedFile: FileItem?      = nil

    // MARK: ‑ Sorting
    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case size = "Size"
        case duration = "Duration"
        var id: String { rawValue }
    }

    var sortedFiles: [FileItem] {
        switch sortOption {
        case .name:
            files.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .size:
            files.sorted { $0.size > $1.size }
        case .duration:
            files.sorted { ($0.duration ?? -1) > ($1.duration ?? -1) }
        }
    }

    // MARK: ‑ Public API (вызывается View)

    func loadFiles(host: String, token: String) async {
        errorMessage = nil
        isLoading    = true
        defer { isLoading = false }

        switch await FileService.shared.fetchFiles(host: host, token: token) {
        case .success(let fetched):
            files = fetched
        case .failure(let error):
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unknown error"
        }
    }

    func delete(_ file: FileItem, host: String, token: String) async {
        switch await FileService.shared.deleteFile(name: file.name, host: host, token: token) {
        case .success:
            files.removeAll { $0 == file }
        case .failure(let error):
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: ‑ Helpers
    func formatSize(_ bytes: Int) -> String {
        let fmt = ByteCountFormatter()
        fmt.allowedUnits = [.useMB, .useKB]
        fmt.countStyle   = .file
        return fmt.string(fromByteCount: .init(bytes))
    }
}
