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
    @State private var host: String = StorageService.shared.loadHost() ?? ""
    
    var body: some View {
        VStack(spacing: 20) {
            HostAndPortInputView(host: $host)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
        
            Button("Продолжить") {
                StorageService.shared.saveHost(host)
                controller.send(.hostEntered(host))
            }
            .disabled(host.isEmpty)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
