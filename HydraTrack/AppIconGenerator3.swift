//
//  AppIconGenerator3.swift
//  HydraTrack
//
//  Minimalist "H" logo with water theme

import SwiftUI

struct AppIconView3: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.55, blue: 0.95),
                    Color(red: 0.0, green: 0.75, blue: 1.0),
                    Color(red: 0.0, green: 0.85, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Large "H" letter
            ZStack {
                // H letter with water fill effect
                Text("H")
                    .font(.system(size: 600, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.9),
                                Color(red: 0.7, green: 0.95, blue: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)

                // Water droplet accent
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .offset(x: 120, y: -180)

                // Small droplet
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 60, height: 60)
                    .offset(x: 140, y: -80)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconView3()
}
