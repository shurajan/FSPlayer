//
//  FSPlayerApp.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 16.04.2025.
//

import SwiftUI

@main
struct FSPlayerApp: App {
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.dynamicColor(light: .black, dark: .white))
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.dynamicColor(light: .black, dark: .white))
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        UINavigationBar.appearance().tintColor = UIColor(Color.dynamicColor(light: .black, dark: .white))
    }
    
    var body: some Scene {
        WindowGroup {
            FSPlayerView()
        }
    }
}
