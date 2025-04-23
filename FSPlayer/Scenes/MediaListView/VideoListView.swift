import SwiftUI

struct VideoListView: View {
    // Внешние зависимости
    @EnvironmentObject private var session: SessionStorage
    @Binding        var navigationPath: [NavigationDestination]

    // ViewModel
    @StateObject private var viewModel = VideoListViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading videos…")
                    .padding()
            }

            if let message = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text(message)
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
                content
            }
        }
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .alert("Delete Video?",
               isPresented: $viewModel.showDeleteConfirmation,
               presenting: viewModel.fileToDelete) { file in
            Button("Delete", role: .destructive) {
                Task { await delete(file) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { file in
            Text("Are you sure you want to delete \"\(file.name)\"?")
        }
        .task { await initialLoad() }
        .fullScreenCover(item: $viewModel.selectedFile) { file in
            VideoPlayerView(file: file, session: session)
                .environmentObject(session)
        }
    }
}

// MARK: ‑ Private subviews & helpers
private extension VideoListView {
    var content: some View {
        VStack(spacing: 10) {
            // Сортировка
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(VideoListViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Список файлов
            List {
                ForEach(viewModel.sortedFiles, id: \.id) { file in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(file.name)
                                .font(.headline)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.selectedFile = file }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.fileToDelete           = file
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await refresh() }
        }
    }

    // MARK: ‑ Intents
    func initialLoad() async {
        guard let host = session.host, let token = session.token else { return }
        await viewModel.loadFiles(host: host, token: token)
    }

    func refresh() {
        Task { await initialLoad() }
    }

    func delete(_ file: FileItem) async {
        guard let host = session.host, let token = session.token else { return }
        await viewModel.delete(file, host: host, token: token)
    }
}
