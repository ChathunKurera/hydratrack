//
//  AppIconGenerator2.swift
//  HydraTrack
//
//  Alternative water bottle icon design

import SwiftUI

struct AppIconView2: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.5, blue: 0.9),
                    Color(red: 0.0, green: 0.7, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Bottle cap
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 180, height: 80)

                // Bottle neck
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 150, height: 60)

                // Main bottle body
                ZStack {
                    // Bottle outline
                    RoundedRectangle(cornerRadius: 60)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 400, height: 650)

                    // Water fill (70% full)
                    VStack {
                        Spacer()

                        ZStack {
                            // Water body
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.9, blue: 1.0).opacity(0.8),
                                            Color(red: 0.2, green: 0.8, blue: 1.0).opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 360, height: 455)

                            // Water surface wave
                            WaveSurface()
                                .fill(Color(red: 0.5, green: 1.0, blue: 1.0).opacity(0.4))
                                .frame(width: 360, height: 30)
                                .offset(y: -227)

                            // Highlight reflection
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 300)
                                .offset(x: -100, y: -50)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .frame(width: 360, height: 455)
                        .padding(.bottom, 15)
                    }
                    .frame(height: 650)

                    // Percentage text
                    Text("70%")
                        .font(.system(size: 140, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .offset(y: 50)
                }
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

struct WaveSurface: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height / 2))

        for x in stride(from: 0, through: rect.width, by: 5) {
            let relativeX = x / 60
            let sine = sin(relativeX * .pi)
            let y = rect.height / 2 + sine * 8
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    AppIconView2()
}
