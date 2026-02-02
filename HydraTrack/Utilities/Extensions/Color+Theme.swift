//
//  Color+Theme.swift
//  HydraTrack
//

import SwiftUI

extension Color {
    // Primary colors
    static let primaryBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let secondaryBlue = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let accentWater = Color(red: 0.0, green: 0.8, blue: 1.0)

    // Success/Progress colors
    static let successGreen = Color.green
    static let warningOrange = Color.orange
    static let dangerRed = Color.red

    // Adaptive colors for high contrast
    static var adaptivePrimary: Color {
        Color(UIColor { traits in
            traits.accessibilityContrast == .high
                ? UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0)
                : UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        })
    }

    static var adaptiveBackground: Color {
        Color(UIColor { traits in
            traits.accessibilityContrast == .high
                ? (traits.userInterfaceStyle == .dark ? .black : .white)
                : (traits.userInterfaceStyle == .dark ? .systemBackground : .secondarySystemBackground)
        })
    }
}
