//
//  GoalCalculationView.swift
//  HydraTrack
//

import SwiftUI

struct GoalCalculationView: View {
    let age: Int
    let weight: Double
    let activityLevel: ActivityLevel
    let onContinue: () -> Void

    private var breakdown: GoalBreakdown {
        GoalCalculator.getBreakdown(age: age, weightKg: weight, activityLevel: activityLevel)
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Your Hydration Goal")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                Text("\(breakdown.finalGoal) mL/day")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.primaryBlue)

                VStack(alignment: .leading, spacing: 12) {
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
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Text(Constants.healthDisclaimer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
