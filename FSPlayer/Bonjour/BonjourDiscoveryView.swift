import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct BonjourDiscoveryView: View {
    @ObservedObject var controller: BonjourDiscoveryController
    @Binding var selectedHostname: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                searchControlSection
                servicesList
            }
            .padding()
            .navigationTitle("Найти сервер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        controller.stopDiscovery()
                        dismiss()
                    }
                }
            }
            .onChange(of: controller.selectedServer) { oldValue, newValue in
                if let hostname = newValue {
                    selectedHostname = hostname
                    dismiss()
                }
            }
        }
        .onAppear {
            controller.startDiscovery()
        }
        .onDisappear {
            controller.stopDiscovery()
        }
    }
    
    // MARK: - UI Components
    
    private var searchControlSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(controller.isDiscovering ? "Остановить поиск" : "Начать поиск") {
                    if controller.isDiscovering {
                        controller.stopDiscovery()
                    } else {
                        controller.startDiscovery()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                if controller.isDiscovering {
                    ProgressView()
                }
            }
            
            if controller.isDiscovering {
                Text("Поиск серверов в локальной сети...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var servicesList: some View {
        List {
            if controller.discoveredServices.isEmpty {
                Text("Серверы не найдены")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(controller.discoveredServices) { service in
                    ServiceRow(
                        service: service,
                        onTap: {
                            handleServiceTap(service)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleServiceTap(service)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
    
    private func handleServiceTap(_ service: MediaFSBrowser.DiscoveredService) {
        if service.isResolved {
            controller.selectServer(service)
        }
        // Не нужно явно вызывать resolveService,
        // так как это теперь происходит автоматически в MediaFSBrowser
    }
}
