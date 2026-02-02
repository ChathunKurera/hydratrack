//
//  PresetDrinkButton.swift
//  HydraTrack
//

import SwiftUI

struct PresetDrinkButton: View {
    let preset: PresetDrink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon with plus badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: preset.icon)
                        .font(.system(size: 34))
                        .foregroundColor(.primaryBlue)

                    // Plus badge in top-right corner
                    Circle()
                        .fill(Color.primaryBlue)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Text("+")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: -4)
                }
                .frame(height: 40)

                // Drink name below icon
                Text(preset.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(12)
        }
        .accessibilityLabel("\(preset.name), \(preset.volumeMl) milliliters")
        .accessibilityHint("Adds \(preset.effectiveHydrationMl) milliliters of effective hydration to your daily total")
        .accessibilityAddTraits(.isButton)
    }
}
