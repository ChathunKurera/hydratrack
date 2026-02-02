//
//  GenderView.swift
//  HydraTrack
//

import SwiftUI

struct GenderView: View {
    @Binding var gender: Gender
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Gender")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("This helps us provide better recommendations")
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                ForEach(Gender.allCases, id: \.self) { genderOption in
                    Button(action: {
                        gender = genderOption
                    }) {
                        HStack {
                            Text(genderOption.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if gender == genderOption {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(gender == genderOption ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
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
