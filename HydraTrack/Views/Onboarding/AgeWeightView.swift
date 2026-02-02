//
//  AgeWeightView.swift
//  HydraTrack
//

import SwiftUI

struct AgeWeightView: View {
    @Binding var age: Int
    @Binding var weight: Double
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Help us personalize your hydration goal")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Age")
                        .font(.headline)
                    TextField("Age", value: $age, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Weight (kg)")
                        .font(.headline)
                    TextField("Weight", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
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
                    .background(isValid ? Color.primaryBlue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isValid)
            .padding(.horizontal)
        }
        .padding()
    }

    private var isValid: Bool {
        age >= 10 && age <= 120 && weight >= 30 && weight <= 300
    }
}
