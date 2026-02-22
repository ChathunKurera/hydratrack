//
//  ProfileSettingsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager

    @AppStorage("units") private var units: VolumeUnit = .milliliters

    @State private var age: Int = 25
    @State private var weight: Double = 70
    @State private var gender: Gender = .preferNotToSay
    @State private var activityLevel: ActivityLevel = .lightlyActive
    @State private var hasLoaded = false

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var breakdown: GoalBreakdown {
        GoalCalculator.getBreakdown(age: age, weightKg: weight, activityLevel: activityLevel)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("Age", value: $age, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("years")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Personal Info", systemImage: "figure.stand")
            }

            Section {
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
            } header: {
                Label("Gender", systemImage: "person.2")
            }

            Section {
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                        }
                        .tag(level)
                    }
                }
                .pickerStyle(.inline)

                Text(activityLevel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Activity Level", systemImage: "figure.run")
            }

            Section {
                HStack {
                    Text("Calculated Goal")
                    Spacer()
                    Text(units.format(breakdown.finalGoal))
                        .foregroundColor(.primaryBlue)
                        .fontWeight(.bold)
                }
            } footer: {
                Text("Your daily goal is calculated based on your age, weight, and activity level.")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if !hasLoaded {
                loadProfile()
                hasLoaded = true
            }
        }
    }

    private var isValid: Bool {
        age >= 10 && age <= 120 && weight >= 30 && weight <= 300
    }

    private func loadProfile() {
        if let profile = dataService.getUserProfile() {
            age = profile.age
            weight = profile.weightKg
            gender = profile.gender
            activityLevel = profile.activityLevel
        }
    }

    private func saveProfile() {
        if let profile = dataService.getUserProfile() {
            profile.age = age
            profile.weightKg = weight
            profile.gender = gender
            profile.activityLevel = activityLevel
            dataService.updateUserProfile(profile)

            // Reschedule notifications
            let settings = AppSettings()
            notificationManager.scheduleReminders(
                wakeTime: settings.wakeTime,
                sleepTime: settings.sleepTime,
                frequency: settings.notificationFrequency
            )
        }
        dismiss()
    }
}

#Preview {
    NavigationView {
        ProfileSettingsView()
    }
}
