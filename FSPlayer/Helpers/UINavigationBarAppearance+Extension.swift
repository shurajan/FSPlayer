//
//  UINavigationBarAppearance+Extension.swift
//  FSPlayer
//
//  Created by Alexander Bralnin on 26.04.2025.
//

import SwiftUI

extension UINavigationBarAppearance {
    static func themedAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.dynamicColor(light: .black, dark: .white))
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.dynamicColor(light: .black, dark: .white))
        ]
        appearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.dynamicColor(light: .black, dark: .white))
        ]
        return appearance
    }
}
