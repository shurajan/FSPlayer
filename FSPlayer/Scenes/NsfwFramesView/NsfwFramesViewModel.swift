//
//  NsfwFramesViewModel.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//

import SwiftUI

@MainActor
final class NsfwFramesViewModel: ObservableObject {
    @Published var images: [ImageItemModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let video: VideoItemModel

    init(video: VideoItemModel) {
        self.video = video
    }

    func load(host: String?, token: String?) async {
        guard let token, !token.isEmpty else {
            errorMessage = "Token is missing"
            return
        }
        guard let host, !host.isEmpty else {
            errorMessage = "Host is missing"
            return
        }
        guard let nsfwframesURL = video.nsfwframesURL else {
            errorMessage = "No NSFW frames URL"
            return
        }

        isLoading = true
        errorMessage = nil

        let result = await NsfwService.shared.fetchFiles(host: host, url: nsfwframesURL, token: token)
        isLoading = false

        switch result {
        case .success(let files):
            images = files
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
