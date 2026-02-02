//
//  TodayIntakeCard.swift
//  HydraTrack
//

import SwiftUI

struct TodayIntakeCard: View {
    let intake: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(intake) / Double(goal), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var status: String {
        if percentage >= 100 {
            return "Goal Reached! 🎉"
        } else if percentage >= 75 {
            return "Almost There!"
        } else if percentage >= 50 {
            return "Halfway There"
        } else if percentage >= 25 {
            return "Keep Going"
        } else {
            return "Just Getting Started"
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Today's Intake")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("\(intake) mL")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("of \(goal) mL goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(percentage)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primaryBlue)

                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.primaryBlue, .accentWater],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.spring(duration: 0.8), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    TodayIntakeCard(intake: 1800, goal: 2500)
        .padding()
}
