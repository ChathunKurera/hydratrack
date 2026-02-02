//
//  ActivityLevelView.swift
//  HydraTrack
//

import SwiftUI

struct ActivityLevelView: View {
    @Binding var activityLevel: ActivityLevel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Activity Level")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("How active are you?")
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button(action: {
                        activityLevel = level
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if activityLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.primaryBlue)
                                }
                            }
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(activityLevel == level ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                }
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
