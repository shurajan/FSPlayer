//
//  ServiceRow.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 18.04.2025.
//

import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct ServiceRow: View {
    let service: BonjourDiscoveryService.DiscoveredService
    let resolved: (hostname: String, port: Int)?
    let error: String?
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
        if let resolved = resolved {
            // Если сервис успешно разрешен
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("\(resolved.hostname):\(resolved.port)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 2)
        } else if let error = error {
            // Если произошла ошибка при разрешении
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Ошибка: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.top, 2)
        } else {
            // Если сервис еще не разрешен
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                
                Text("Нажмите для получения адреса...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
    }
}
