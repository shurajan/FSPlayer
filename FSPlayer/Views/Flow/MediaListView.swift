import SwiftUI

struct MediaListView: View {
    @EnvironmentObject var session: SessionViewModel
    @Binding var navigationPath: [NavigationDestination]
    
    @State private var files: [FileItem] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var sortOption: SortOption = .name
    @State private var fileToDelete: FileItem?
    @State private var showDeleteConfirmation = false

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case size = "Size"
        case resolution = "Resolution"

        var id: String { rawValue }
    }

    var sortedFiles: [FileItem] {
        switch sortOption {
        case .name:
            return files.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .size:
            return files.sorted { $0.size > $1.size }
        case .resolution:
            return files.sorted {
                ($0.resolution ?? "").localizedStandardCompare($1.resolution ?? "") == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading files...")
                    .padding()
            }

            if let errorMessage {
                VStack(spacing: 16) {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)

                    Button("Back to Login") {
                        session.logout()
                        navigationPath = []
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 500)
                .padding()
            } else {
                VStack(spacing: 10) {
                    HStack {
                        Text("Sort by:")
                            .font(.subheadline)
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    List {
                        ForEach(sortedFiles) { file in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(file.name)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(formatSize(file.size))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let resolution = file.resolution {
                                    Text("📺 \(resolution)")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await loadFiles()
                    }
                }
            }
        }
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await loadFiles()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .alert("Delete File?", isPresented: $showDeleteConfirmation, presenting: fileToDelete) { file in
            Button("Delete", role: .destructive) {
                Task {
                    await delete(file)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { file in
            Text("Are you sure you want to delete \"\(file.name)\"?")
        }
        .task {
            await loadFiles()
        }
    }

    private func loadFiles() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard let host = session.host, let token = session.token else {
            errorMessage = "Missing credentials"
            return
        }

        let result = await FileService.shared.fetchFiles(host: host, token: token)
        switch result {
        case .success(let fetchedFiles):
            files = fetchedFiles
        case .failure(let error):
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unknown error"
        }
    }

    private func delete(_ file: FileItem) async {
        guard let host = session.host, let token = session.token else {
            errorMessage = "Missing credentials"
            return
        }

        let result = await FileService.shared.deleteFile(name: file.name, host: host, token: token)
        switch result {
        case .success:
            files.removeAll { $0 == file }
        case .failure(let error):
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
