//
//  ManualEntryView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 17.04.2025.
//
//
//  ManualEntryView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 17.04.2025.
//
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct ManualEntryView: View {
    @EnvironmentObject var controller: FSPlayerController // Ваш существующий контроллер
    @State private var host: String = ""
    @State private var showingBonjourDiscovery = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Введите IP или имя хоста", text: $host)
                .textFieldStyle(.roundedBorder)
        
            Button("Продолжить") {
                controller.send(.hostEntered(host))
            }
            .disabled(host.isEmpty)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
