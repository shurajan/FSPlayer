//
//  KeyframeThumbnailView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 13.05.2025.
//

import SwiftUI

struct KeyframeThumbnailView: View {
    let index: Int
    let keyframesURL: String
    let height: CGFloat
    let onTap: (Int) -> Void

    @EnvironmentObject private var session: SessionStorage
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray
                ProgressView()
            }
        }
        .frame(width: height * 16 / 9, height: height)
        .cornerRadius(4)
        .clipped()
        .onTapGesture {
            print("Tapped on \(index)")
            onTap(index)
        }
        .task {
            await load()
        }
    }

    private func load() async {
        guard let host = session.host, let token = session.token else {
            image = UIImage(systemName: "photo")
            return
        }

        let path = "\(keyframesURL)\(index).jpg"
        let result = await ImageService.shared.fetchImage(from: path, host: host, token: token)

        switch result {
        case .success(let img):
            image = img
        case .failure:
            image = UIImage(systemName: "photo")
        }
    }
}
