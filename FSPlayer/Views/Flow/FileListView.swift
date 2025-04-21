import SwiftUI

struct FileListView: View {
    @EnvironmentObject var controller: FSPlayerController

    var body: some View {
        VStack {
            List(controller.files) { file in
                FileRowView(file: file)
            }
            .refreshable {
                await controller.fetchFilesList()
            }
            .listStyle(PlainListStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // или .clear
    }
}

struct FileRowView: View {
    let file: FileItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            previewImage
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let resolution = file.resolution {
                    Text("Resolution: \(resolution)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var previewImage: some View {
        if let urlString = file.previewURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Image(systemName: "doc")
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundColor(.gray)
    }
}
