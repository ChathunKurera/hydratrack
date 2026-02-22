//
//  StreakBadgeView.swift
//  HydraTrack
//

import SwiftUI

struct StreakBadgeView: View {
    let streak: Int
    let isFrozen: Bool

    @State private var flameScale: CGFloat = 1.0
    @State private var pulseCount = 0

    private var tierEmoji: String? {
        if streak >= 100 { return "💎" }
        if streak >= 30 { return "🏆" }
        if streak >= 7 { return "⭐" }
        return nil
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .font(.system(size: 20))
                .scaleEffect(flameScale)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(streak) day streak")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let emoji = tierEmoji {
                        Text(emoji)
                            .font(.caption)
                    }
                }

                if isFrozen {
                    HStack(spacing: 3) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text("Streak freeze active")
                            .font(.caption2)
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .onAppear {
            // Pulse flame 3 times on appear
            pulseFlame()
        }
    }

    private func pulseFlame() {
        guard pulseCount < 3 else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            flameScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                flameScale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pulseCount += 1
                pulseFlame()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBadgeView(streak: 3, isFrozen: false)
        StreakBadgeView(streak: 8, isFrozen: false)
        StreakBadgeView(streak: 5, isFrozen: true)
    }
}
