//
//  NotificationPermissionView.swift
//  HydraTrack
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryBlue)

            Text("Stay on Track")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Get friendly reminders throughout the day to help you reach your hydration goal.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 15) {
                FeatureRow(icon: "clock", text: "4 daily reminders")
                FeatureRow(icon: "moon.stars", text: "Scheduled during your wake hours")
                FeatureRow(icon: "brain", text: "Smart notifications (optional)")
            }
            .padding()

            Spacer()

            Button(action: {
                Task {
                    try? await notificationManager.requestAuthorization()
                    onContinue()
                }
            }) {
                Text("Enable Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button(action: onContinue) {
                Text("Skip for Now")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primaryBlue)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
