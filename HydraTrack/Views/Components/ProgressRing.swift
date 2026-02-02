//
//  ProgressRing.swift
//  HydraTrack
//

import SwiftUI

struct ProgressRing: View {
    let current: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    @State private var waveOffset: CGFloat = 0
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Water Bottle Container
            ZStack {
                // Bottle outline
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.primaryBlue.opacity(0.3), lineWidth: 4)

                // Water fill with wave effect
                WaveShape(offset: waveOffset, percent: animatedProgress)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentWater.opacity(0.8),
                                Color.primaryBlue.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .padding(4)

                // Animated wave overlay
                WaveShape(offset: waveOffset + 10, percent: animatedProgress)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentWater.opacity(0.3),
                                Color.primaryBlue.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .padding(4)
            }
            .frame(width: 180, height: 240)

            // Percentage and stats
            VStack(spacing: 12) {
                Spacer()

                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(animatedProgress > 0.3 ? .white : .primaryBlue)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)

                    Text("\(current) / \(goal) mL")
                        .font(.headline)
                        .foregroundColor(animatedProgress > 0.2 ? .white : .secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                .padding(.bottom, 30)
            }
            .frame(height: 240)
        }
        .onAppear {
            // Animate progress fill
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = progress
            }

            // Start wave animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = 360
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

// Wave shape for water effect
struct WaveShape: Shape {
    var offset: CGFloat
    var percent: Double

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let waveHeight: CGFloat = 8
        let yOffset = (1 - CGFloat(percent)) * rect.height

        path.move(to: CGPoint(x: 0, y: yOffset))

        // Optimized: Use stride with larger step for better performance
        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / 50
            let sine = sin((relativeX + offset / 50) * .pi)
            let y = yOffset + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    ProgressRing(current: 1500, goal: 2500)
}
