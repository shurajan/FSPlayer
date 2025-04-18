import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct ServiceRow: View {
    let service: MediaFSBrowser.DiscoveredService
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Название сервиса
            Text(service.name)
                .font(.headline)
            
            // Тип сервиса
            Text("Тип: \(service.type)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Статус разрешения
            statusView
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var statusView: some View {
        if service.isResolved, let hostname = service.hostname, let port = service.port {
            // Если сервис успешно разрешен
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("\(hostname):\(port)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 2)
        } else {
            // Если сервис еще не разрешен
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                
                Text("Получение адреса...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
    }
}
