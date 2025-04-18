//
//  BonjourDiscoveryView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

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
                        resolved: controller.resolvedServices[service.id],
                        error: controller.resolvingErrors[service.id],
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
    
    private func handleServiceTap(_ service: BonjourDiscoveryService.DiscoveredService) {
        if controller.resolvedServices[service.id] != nil {
            controller.selectServer(with: service.id)
        } else if controller.resolvingErrors[service.id] == nil {
            controller.resolveService(service)
        }
    }
}
