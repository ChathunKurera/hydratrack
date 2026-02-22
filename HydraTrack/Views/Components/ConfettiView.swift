//
//  ConfettiView.swift
//  HydraTrack
//

import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    private let particleCount = 80
    private let lifetime: TimeInterval = 3.5
    private let colors: [Color] = [
        .blue, .green, .orange, .pink, .purple, .yellow, .red, .cyan, .mint
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                guard elapsed < lifetime else { return }

                for particle in particles {
                    let t = elapsed
                    let gravity: Double = 400

                    let x = particle.startX + particle.velocityX * t
                    let y = particle.startY + particle.velocityY * t + 0.5 * gravity * t * t
                    let rotation = Angle.degrees(particle.rotationSpeed * t)
                    let alpha = max(0, 1.0 - (t / lifetime))

                    guard y < size.height + 50 else { continue }

                    var contextCopy = context
                    contextCopy.translateBy(x: x, y: y)
                    contextCopy.rotate(by: rotation)
                    contextCopy.opacity = alpha

                    let rect = CGRect(
                        x: -particle.width / 2,
                        y: -particle.height / 2,
                        width: particle.width,
                        height: particle.height
                    )
                    contextCopy.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startConfetti()
            }
        }
    }

    private func startConfetti() {
        startTime = .now
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 50...350),
                startY: CGFloat.random(in: -50...(-10)),
                velocityX: CGFloat.random(in: -100...100),
                velocityY: CGFloat.random(in: -400...(-150)),
                width: CGFloat.random(in: 6...12),
                height: CGFloat.random(in: 4...10),
                rotationSpeed: Double.random(in: -360...360),
                color: colors.randomElement() ?? .blue
            )
        }

        // Auto-dismiss after lifetime
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            isActive = false
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotationSpeed: Double
    let color: Color
}
