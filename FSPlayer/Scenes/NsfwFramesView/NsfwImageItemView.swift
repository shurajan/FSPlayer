//
//  NsfwImageItemView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 20.05.2025.
//
import SwiftUI

struct NsfwImageItemView: View {
    let item: ImageItemModel

    @EnvironmentObject private var session: SessionStorage
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var isPreviewPresented = false

    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 90)
                    .clipped()
                    .cornerRadius(8)
                    .onTapGesture {
                        isPreviewPresented = true
                    }
            } else if isLoading {
                ProgressView()
                    .frame(width: 120, height: 90)
            } else {
                Color.red.opacity(0.1)
                    .frame(width: 120, height: 90)
                    .overlay(Text("Error").foregroundColor(.red))
                    .cornerRadius(8)
            }
        }
        .task {
            guard let host = session.host, let token = session.token else { return }
            let result = await ImageService.shared.fetchImage(from: item.urlPath, host: host, token: token)
            isLoading = false
            if case .success(let img) = result {
                image = img
            }
        }
        .fullScreenCover(isPresented: $isPreviewPresented) {
            if let image {
                ZoomableImageView(image: image)
            }
        }
    }
}
