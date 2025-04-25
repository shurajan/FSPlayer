import SwiftUI

struct VideoListView: View {
    // Внешние зависимости
    @EnvironmentObject private var session: SessionStorage
    @Binding var navigationPath: [NavigationDestination]
    
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
                    Task {
                        await refresh()
                    }
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
        .fullScreenCover(item: $viewModel.selectedVideo) { video in
            VideoPlayerView(video: video, session: session)
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
            
            // Список видео
            List {
                ForEach(viewModel.sortedFiles, id: \.id) { video in
                    VideoItemView(video: video) { video, playlist in
                        viewModel.selectedVideo = SelectedVideoItem(video: video, playlist: playlist.name)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.fileToDelete           = video
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
    
    func refresh()  async{
        Task { await initialLoad() }
    }
    
    func delete(_ file: VideoItemModel) async {
        guard let host = session.host, let token = session.token else { return }
        await viewModel.delete(file, host: host, token: token)
    }
}
