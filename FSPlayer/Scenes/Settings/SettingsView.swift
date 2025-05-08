//
//  SettingsView.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 08.05.2025.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings

    var body: some View {
        NavigationView {
            Form {
                Toggle("Enable Performance overlay", isOn: $globalSettings.isPerformanceOverlayEnabled)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
