//
//  WelcomeView.swift
//  HydraTrack
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 100))
                .foregroundColor(.primaryBlue)

            Text("Welcome to HydraTrack")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Stay hydrated, stay healthy.\nTrack your daily water intake with personalized goals and smart reminders.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
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
