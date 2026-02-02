//
//  ProfileEditView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager

    let profile: UserProfile

    @State private var age: Int
    @State private var weight: Double
    @State private var gender: Gender
    @State private var activityLevel: ActivityLevel

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var breakdown: GoalBreakdown {
        GoalCalculator.getBreakdown(age: age, weightKg: weight, activityLevel: activityLevel)
    }

    init(profile: UserProfile) {
        self.profile = profile
        _age = State(initialValue: profile.age)
        _weight = State(initialValue: profile.weightKg)
        _gender = State(initialValue: profile.gender)
        _activityLevel = State(initialValue: profile.activityLevel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Gender") {
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }

                Section("Activity Level") {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Text(activityLevel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Calculated Goal") {
                    HStack {
                        Text("New Daily Goal")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(breakdown.finalGoal) mL")
                            .foregroundColor(.primaryBlue)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        age >= 10 && age <= 120 && weight >= 30 && weight <= 300
    }

    private func saveProfile() {
        profile.age = age
        profile.weightKg = weight
        profile.gender = gender
        profile.activityLevel = activityLevel
        dataService.updateUserProfile(profile)

        // Reschedule notifications with new times if needed
        let settings = AppSettings()
        notificationManager.scheduleReminders(
            wakeTime: settings.wakeTime,
            sleepTime: settings.sleepTime,
            frequency: settings.notificationFrequency
        )

        dismiss()
    }
}
