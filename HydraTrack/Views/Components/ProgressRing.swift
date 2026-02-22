//
//  ProgressRing.swift
//  HydraTrack
//

import SwiftUI

struct ProgressRing: View {
    let current: Int
    let goal: Int
    var unit: VolumeUnit = .milliliters

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var displayText: String {
        let currentDisplay = unit.format(current)
        let goalDisplay = unit.format(goal)
        // Remove unit from current for cleaner display
        let currentValue = unit == .ounces
            ? String(format: "%.1f", unit.convert(from: current))
            : "\(current)"
        let goalValue = unit == .ounces
            ? String(format: "%.1f", unit.convert(from: goal))
            : "\(goal)"
        return "\(currentValue) / \(goalValue) \(unit.abbreviation)"
    }

    @State private var waveOffset: CGFloat = 0
    @State private var animatedProgress: Double = 0
    @State private var waveTimer: Timer?
    @State private var milestone25Hit: Bool = false
    @State private var milestone50Hit: Bool = false
    @State private var milestone75Hit: Bool = false

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

                // Milestone markers
                milestoneMarker(at: 0.25, label: "25%", hit: milestone25Hit)
                milestoneMarker(at: 0.50, label: "50%", hit: milestone50Hit)
                milestoneMarker(at: 0.75, label: "75%", hit: milestone75Hit)
            }
            .frame(width: 180, height: 240)

            // Volume text inside bottle (bottom)
            VStack {
                Spacer()

                Text(displayText)
                    .font(.headline)
                    .foregroundColor(animatedProgress > 0.2 ? .white : .secondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    .padding(.bottom, 24)
            }
            .frame(height: 240)
        }
        .overlay(alignment: .leading) {
            // Floating percentage badge attached to the left edge of the bottle
            floatingPercentageBadge
                .offset(x: -50)
        }
        .onAppear {
            // Set initial milestone states without animation
            milestone25Hit = progress >= 0.25
            milestone50Hit = progress >= 0.50
            milestone75Hit = progress >= 0.75

            // Animate progress fill
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = progress
            }

            // Start wave animation for 10 seconds to save battery
            startWaveAnimation()
        }
        .onDisappear {
            stopWaveAnimation()
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }

            // Detect upward milestone crossings
            if oldValue < 0.25 && newValue >= 0.25 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    milestone25Hit = true
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            if oldValue < 0.50 && newValue >= 0.50 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    milestone50Hit = true
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            if oldValue < 0.75 && newValue >= 0.75 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    milestone75Hit = true
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }

            // Handle downward crossings (undo scenarios)
            if newValue < 0.25 { milestone25Hit = false }
            if newValue < 0.50 { milestone50Hit = false }
            if newValue < 0.75 { milestone75Hit = false }

            // Restart wave animation when progress changes (user added a drink)
            startWaveAnimation()
        }
    }

    // MARK: - Floating Percentage Badge

    private var floatingPercentageBadge: some View {
        let bottleHeight: CGFloat = 240
        let padding: CGFloat = 8
        let usableHeight = bottleHeight - padding * 2
        let yFromBottom = usableHeight * animatedProgress
        // Clamp so badge doesn't go above or below the bottle
        let clampedY = min(max(yFromBottom, 20), usableHeight - 10)
        // Convert to offset from center (center of 240pt frame is at 120)
        let yOffset = (usableHeight / 2 - clampedY)

        return Text("\(percentage)%")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.primaryBlue)
                    .shadow(color: .primaryBlue.opacity(0.4), radius: 4, x: 0, y: 2)
            )
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.6), value: animatedProgress)
    }

    // MARK: - Milestone Marker

    private func milestoneMarker(at threshold: Double, label: String, hit: Bool) -> some View {
        // Position: 240 height, threshold maps to y position from bottom
        let bottleHeight: CGFloat = 240
        let padding: CGFloat = 8 // account for inner padding
        let usableHeight = bottleHeight - padding * 2
        let yFromBottom = usableHeight * threshold
        let yPosition = bottleHeight - padding - yFromBottom

        return HStack(spacing: 4) {
            Rectangle()
                .fill(hit ? Color.white.opacity(0.8) : Color.primaryBlue.opacity(0.3))
                .frame(width: 30, height: 1.5)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(hit ? .white : Color.primaryBlue.opacity(0.4))
        }
        .scaleEffect(hit ? 1.0 : 0.8)
        .position(x: 110, y: yPosition)
    }

    // MARK: - Wave Animation Helpers

    private func startWaveAnimation() {
        // Stop any existing animation
        stopWaveAnimation()

        // Start timer-based wave animation
        var elapsedTime: Double = 0
        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            elapsedTime += 0.05
            waveOffset = CGFloat(elapsedTime * 180) // Smooth wave motion

            // Stop after 10 seconds to save battery
            if elapsedTime >= 10.0 {
                timer.invalidate()
            }
        }
    }

    private func stopWaveAnimation() {
        waveTimer?.invalidate()
        waveTimer = nil
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
