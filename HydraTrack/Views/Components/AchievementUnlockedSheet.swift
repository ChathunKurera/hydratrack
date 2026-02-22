//
//  AchievementUnlockedSheet.swift
//  HydraTrack
//

import SwiftUI

struct AchievementUnlockedSheet: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var animateIcon = false
    @State private var animateText = false

    private var primaryColor: Color {
        if let customColors = achievement.customColors {
            return customColors.primary
        }
        return categoryColor
    }

    private var secondaryColor: Color {
        if let customColors = achievement.customColors {
            return customColors.secondary
        }
        return categoryColor
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .streak: return .orange
        case .volume: return .blue
        case .consistency: return .green
        case .milestone: return .purple
        case .variety: return .pink
        case .timing: return .cyan
        case .challenge: return .red
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration text
            Text("Achievement Unlocked!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 20)

            // Achievement icon with animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [primaryColor.opacity(0.3), primaryColor.opacity(0)],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateIcon ? 1.2 : 0.8)
                    .opacity(animateIcon ? 1 : 0)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: primaryColor.opacity(0.5), radius: 20, x: 0, y: 10)
                    .scaleEffect(animateIcon ? 1 : 0.5)

                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateIcon ? 1 : 0.5)
            }

            // Achievement title
            Text(achievement.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 20)

            // Achievement description
            Text(achievement.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 20)

            // Category badge
            Text(achievement.category.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .cornerRadius(20)
                .opacity(animateText ? 1 : 0)

            Spacer()

            // Dismiss button
            Button(action: {
                onDismiss()
                dismiss()
            }) {
                Text("Awesome!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .opacity(animateText ? 1 : 0)
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Trigger animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateIcon = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateText = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

#Preview {
    AchievementUnlockedSheet(
        achievement: Achievement(
            id: "first_goal",
            title: "First Goal!",
            description: "Complete your daily hydration goal for the first time",
            icon: "flag.fill",
            category: .milestone,
            customColors: nil
        ),
        onDismiss: {}
    )
}
