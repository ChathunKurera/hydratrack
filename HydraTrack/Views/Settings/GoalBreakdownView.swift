//
//  GoalBreakdownView.swift
//  HydraTrack
//

import SwiftUI

struct GoalBreakdownView: View {
    let breakdown: GoalBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Goal Calculation Breakdown")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("Base Calculation:")
                    Spacer()
                    Text(breakdown.baseCalculation)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Base Amount:")
                    Spacer()
                    Text("\(breakdown.baseAmount) mL")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Activity Bonus:")
                    Spacer()
                    Text("+\(breakdown.activityBonus) mL")
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack {
                    Text("Daily Goal:")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(breakdown.finalGoal) mL")
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)
                }

                if breakdown.wasClamped {
                    Text("Adjusted to recommended range (1500-3200 mL)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)

            Text(Constants.healthDisclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
