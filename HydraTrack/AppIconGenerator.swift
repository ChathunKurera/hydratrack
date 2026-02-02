//
//  AppIconGenerator.swift
//  HydraTrack
//
//  Use this view to generate the app icon
//  Run in preview, screenshot at 1024x1024, then use AppIconGenerator.com or similar

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.6, blue: 1.0),
                    Color(red: 0.0, green: 0.8, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Water droplet shape
            ZStack {
                // Main droplet
                DropletShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 600, height: 700)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                // Highlight
                DropletShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 600, height: 700)
                    .offset(x: -50, y: -30)

                // Mini droplet inside
                Circle()
                    .fill(Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.6))
                    .frame(width: 80, height: 80)
                    .offset(x: 40, y: -80)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

// Custom droplet shape
struct DropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Start at top point
        path.move(to: CGPoint(x: width * 0.5, y: 0))

        // Right curve
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.7),
            control1: CGPoint(x: width * 0.9, y: height * 0.2),
            control2: CGPoint(x: width, y: height * 0.5)
        )

        // Bottom right curve
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width, y: height * 0.9),
            control2: CGPoint(x: width * 0.75, y: height)
        )

        // Bottom left curve
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.7),
            control1: CGPoint(x: width * 0.25, y: height),
            control2: CGPoint(x: 0, y: height * 0.9)
        )

        // Left curve back to top
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.5),
            control2: CGPoint(x: width * 0.1, y: height * 0.2)
        )

        return path
    }
}

#Preview {
    AppIconView()
}
