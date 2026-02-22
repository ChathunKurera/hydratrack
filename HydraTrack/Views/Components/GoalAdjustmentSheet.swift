//
//  GoalAdjustmentSheet.swift
//  HydraTrack
//

import SwiftUI

struct GoalAdjustmentSheet: View {
    let suggestion: GoalAdjustmentSuggestion
    let onAccept: (Int) -> Void
    let onDismiss: () -> Void

    @State private var customGoal: String = ""
    @State private var showCustomInput = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: iconName)
                        .font(.system(size: 44))
                        .foregroundColor(iconBackgroundColor)
                }
                .padding(.top, 20)

                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Reason
                Text(suggestion.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Stats Card
                VStack(spacing: 16) {
                    HStack {
                        StatColumn(label: "Current Goal", value: "\(suggestion.currentGoal) mL")

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        StatColumn(label: "Suggested", value: "\(suggestion.suggestedGoal) mL", highlight: true)
                    }

                    Divider()

                    HStack {
                        Text("Your 3-day average:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(suggestion.averageIntake) mL")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Change:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(suggestion.type == .increase ? "+" : "-")\(suggestion.changeAmount) mL (\(suggestion.changePercentage)%)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(suggestion.type == .increase ? .green : .orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    // Accept suggested goal
                    Button(action: {
                        onAccept(suggestion.suggestedGoal)
                        dismiss()
                    }) {
                        Text("Set Goal to \(suggestion.suggestedGoal) mL")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue)
                            .cornerRadius(12)
                    }

                    // Custom goal input
                    if showCustomInput {
                        HStack {
                            TextField("Enter custom goal (mL)", text: $customGoal)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Set") {
                                if let goal = Int(customGoal), goal >= 1500, goal <= 3200 {
                                    onAccept(goal)
                                    dismiss()
                                }
                            }
                            .disabled(customGoal.isEmpty)
                            .foregroundColor(.primaryBlue)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                    } else {
                        Button(action: {
                            showCustomInput = true
                            customGoal = "\(suggestion.suggestedGoal)"
                        }) {
                            Text("Enter Custom Goal")
                                .font(.subheadline)
                                .foregroundColor(.primaryBlue)
                        }
                    }

                    // Dismiss
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var title: String {
        switch suggestion.type {
        case .increase:
            return "Ready for a Challenge?"
        case .decrease:
            return "Let's Adjust Your Goal"
        }
    }

    private var iconName: String {
        switch suggestion.type {
        case .increase:
            return "arrow.up.circle.fill"
        case .decrease:
            return "arrow.down.circle.fill"
        }
    }

    private var iconBackgroundColor: Color {
        switch suggestion.type {
        case .increase:
            return .green
        case .decrease:
            return .orange
        }
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(highlight ? .primaryBlue : .primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GoalAdjustmentSheet(
        suggestion: GoalAdjustmentSuggestion(
            type: .decrease,
            currentGoal: 2500,
            suggestedGoal: 2000,
            reason: "Your intake has been below 75% for 3 days. Let's set a more achievable target!",
            averageIntake: 1800
        ),
        onAccept: { _ in },
        onDismiss: { }
    )
}
