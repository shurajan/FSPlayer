//
//  VideoListView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 24.04.2025.
//

import SwiftUI

struct VideoListView: View {
    @EnvironmentObject private var session: SessionStorage
    @EnvironmentObject private var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: [NavigationDestination]
    
    @StateObject private var viewModel = VideoListViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading videos…")
                    .padding()
            } else if let message = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text(message)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        session.logout()
                        navigationPath = []
                    }) {
                        Text("Back to Login")
                            .font(.headline)
                            .foregroundColor(Color.dynamicColor(light: .black, dark: .white))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.dynamicColor(light: .black.opacity(0.1), dark: .white.opacity(0.1)))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: 500)
                .padding()
            } else {
                content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.dynamicColor(light: .black, dark: .white))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task { await refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.dynamicColor(light: .black, dark: .white))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.dynamicColor(light: .black, dark: .white))
                }
            }
        }
        .navigationTitle("Media")
        .navigationBarBackButtonHidden(true) 
        .alert("Delete Video?", isPresented: $viewModel.showDeleteConfirmation, presenting: viewModel.fileToDelete) { file in
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
                .environmentObject(globalSettings)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(globalSettings)
        }
    }
}

// MARK: - Private Subviews & Helpers

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
            
            List {
                ForEach(viewModel.sortedFiles, id: \.id) { video in
                    VideoItemView(video: video) { video in
                        viewModel.selectedVideo = video
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.fileToDelete = video
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

    func initialLoad() async {
        guard let host = session.host, let token = session.token else { return }
        await viewModel.loadVideos(host: host, token: token)
    }
    
    func refresh() async {
        await initialLoad()
    }
    
    func delete(_ file: VideoItemModel) async {
        guard let host = session.host, let token = session.token else { return }
        await viewModel.delete(file, host: host, token: token)
    }
}
