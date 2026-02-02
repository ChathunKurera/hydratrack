//
//  SettingsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @AppStorage("units") private var units: VolumeUnit = .milliliters
    @AppStorage("wakeTimeMinutes") private var wakeTimeMinutes: Int = 420 // 7:00 AM
    @AppStorage("sleepTimeMinutes") private var sleepTimeMinutes: Int = 1380 // 11:00 PM
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") private var notificationFrequency: Int = 4
    @AppStorage("smartRemindersEnabled") private var smartRemindersEnabled: Bool = false
    @AppStorage("smartReminderThresholdHours") private var smartReminderThresholdHours: Int = 2
    @AppStorage("healthKitSleepEnabled") private var healthKitSleepEnabled: Bool = false

    @State private var showingProfileEdit = false
    @State private var showingGoalBreakdown = false
    @State private var showingHealthKitAuth = false
    @State private var customGoal: String = ""
    @State private var useCustomGoal: Bool = false
    @State private var cachedProfile: UserProfile?
    @State private var todayGoalOverride: String = ""
    @State private var hasTodayOverride: Bool = false

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var userProfile: UserProfile? {
        cachedProfile ?? dataService.getUserProfile()
    }

    private func updateProfileCache() {
        cachedProfile = dataService.getUserProfile()
    }

    private var wakeTime: Date {
        Calendar.current.date(bySettingHour: wakeTimeMinutes / 60, minute: wakeTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private var sleepTime: Date {
        Calendar.current.date(bySettingHour: sleepTimeMinutes / 60, minute: sleepTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section("Profile") {
                    if let profile = userProfile {
                        HStack {
                            Text("Age")
                            Spacer()
                            Text("\(profile.age) years")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Weight")
                            Spacer()
                            Text("\(Int(profile.weightKg)) kg")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Gender")
                            Spacer()
                            Text(profile.gender.rawValue)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Activity Level")
                            Spacer()
                            Text(profile.activityLevel.rawValue)
                                .foregroundColor(.secondary)
                        }

                        Button("Edit Profile") {
                            showingProfileEdit = true
                        }
                    }
                }

                // Goal Section
                Section("Daily Goal") {
                    if let profile = userProfile {
                        HStack {
                            Text("Current Goal")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(profile.dailyGoalMl) mL")
                                .foregroundColor(.primaryBlue)
                                .fontWeight(.bold)
                        }

                        Button("View Breakdown") {
                            showingGoalBreakdown = true
                        }

                        Toggle("Use Custom Goal", isOn: $useCustomGoal)
                            .onChange(of: useCustomGoal) { _, newValue in
                                if !newValue {
                                    dataService.setCustomGoal(nil, for: profile)
                                }
                            }

                        if useCustomGoal {
                            HStack {
                                TextField("Goal (mL)", text: $customGoal)
                                    .keyboardType(.numberPad)

                                Button("Set") {
                                    if let goal = Int(customGoal), goal >= 1500 && goal <= 4500 {
                                        dataService.setCustomGoal(goal, for: profile)
                                    }
                                }
                                .disabled(customGoal.isEmpty)
                            }
                        }
                    }
                }

                // Today's Goal Override Section
                Section {
                    if let profile = userProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Regular Goal")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(profile.dailyGoalMl) mL")
                                    .foregroundColor(.secondary)
                            }

                            if hasTodayOverride, let override = dataService.getTodayGoalOverride() {
                                HStack {
                                    Text("Today's Goal")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(override) mL")
                                        .foregroundColor(.orange)
                                        .fontWeight(.bold)
                                }

                                Button(role: .destructive) {
                                    dataService.clearTodayGoalOverride()
                                    hasTodayOverride = false
                                    todayGoalOverride = ""
                                } label: {
                                    Text("Reset to Regular Goal")
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                HStack {
                                    TextField("Today's Goal (mL)", text: $todayGoalOverride)
                                        .keyboardType(.numberPad)

                                    Button("Set") {
                                        if let goal = Int(todayGoalOverride), goal >= 1000 && goal <= 5000 {
                                            dataService.setTodayGoalOverride(goalMl: goal)
                                            hasTodayOverride = true
                                        }
                                    }
                                    .disabled(todayGoalOverride.isEmpty)
                                }
                            }

                            Text("Override your daily goal for today only. Useful when you have different activity levels.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Today's Goal")
                } footer: {
                    Text("This override only applies to today and will reset tomorrow.")
                }

                // Units Section
                Section("Units") {
                    Picker("Volume Unit", selection: $units) {
                        ForEach(VolumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Notifications Section
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                    scheduleNotifications()
                                }
                            } else {
                                notificationManager.cancelAllReminders()
                            }
                        }

                    if notificationsEnabled {
                        Stepper("Reminders per day: \(notificationFrequency)", value: $notificationFrequency, in: 1...10)
                            .onChange(of: notificationFrequency) { _, _ in
                                scheduleNotifications()
                            }

                        Toggle("Smart Reminders", isOn: $smartRemindersEnabled)
                            .onChange(of: smartRemindersEnabled) { _, newValue in
                                notificationManager.scheduleSmartReminders(enabled: newValue, modelContext: modelContext)
                            }

                        if smartRemindersEnabled {
                            Stepper("Check every \(smartReminderThresholdHours) hour\(smartReminderThresholdHours == 1 ? "" : "s")", value: $smartReminderThresholdHours, in: 1...6)

                            Text("Smart reminders send notifications when you haven't logged a drink for a while.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Sleep Schedule Section
                Section("Sleep Schedule") {
                    if healthKitManager.isHealthKitAvailable() {
                        Toggle("Use Apple Health", isOn: $healthKitSleepEnabled)
                            .onChange(of: healthKitSleepEnabled) { oldValue, newValue in
                                if newValue {
                                    requestHealthKitAccess()
                                } else {
                                    healthKitManager.sleepSchedule = nil
                                }
                            }
                    }

                    if !healthKitSleepEnabled {
                        DatePicker("Wake Time", selection: Binding(
                            get: { wakeTime },
                            set: { newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                wakeTimeMinutes = (components.hour ?? 7) * 60 + (components.minute ?? 0)
                                scheduleNotifications()
                            }
                        ), displayedComponents: .hourAndMinute)

                        DatePicker("Sleep Time", selection: Binding(
                            get: { sleepTime },
                            set: { newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                sleepTimeMinutes = (components.hour ?? 23) * 60 + (components.minute ?? 0)
                                scheduleNotifications()
                            }
                        ), displayedComponents: .hourAndMinute)
                    } else if let schedule = healthKitManager.sleepSchedule {
                        HStack {
                            Text("Wake Time")
                            Spacer()
                            Text(schedule.wake, style: .time)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Sleep Time")
                            Spacer()
                            Text(schedule.sleep, style: .time)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingProfileEdit) {
            if let profile = userProfile {
                ProfileEditView(profile: profile)
            }
        }
        .sheet(isPresented: $showingGoalBreakdown) {
            if let profile = userProfile {
                NavigationView {
                    ScrollView {
                        GoalBreakdownView(
                            breakdown: GoalCalculator.getBreakdown(
                                age: profile.age,
                                weightKg: profile.weightKg,
                                activityLevel: profile.activityLevel
                            )
                        )
                        .padding()
                    }
                    .navigationTitle("Goal Breakdown")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingGoalBreakdown = false
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            updateProfileCache()
            if let profile = userProfile, profile.customGoalMl != nil {
                useCustomGoal = true
                customGoal = "\(profile.customGoalMl!)"
            }

            // Check for today's goal override
            if let override = dataService.getTodayGoalOverride() {
                hasTodayOverride = true
                todayGoalOverride = "\(override)"
            }
        }
    }

    private func scheduleNotifications() {
        guard notificationsEnabled else { return }
        notificationManager.scheduleReminders(
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            frequency: notificationFrequency
        )
    }

    private func requestHealthKitAccess() {
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                if let schedule = try await healthKitManager.fetchSleepSchedule() {
                    await MainActor.run {
                        healthKitManager.sleepSchedule = schedule
                        let wakeComponents = Calendar.current.dateComponents([.hour, .minute], from: schedule.wake)
                        wakeTimeMinutes = (wakeComponents.hour ?? 7) * 60 + (wakeComponents.minute ?? 0)

                        let sleepComponents = Calendar.current.dateComponents([.hour, .minute], from: schedule.sleep)
                        sleepTimeMinutes = (sleepComponents.hour ?? 23) * 60 + (sleepComponents.minute ?? 0)

                        scheduleNotifications()
                    }
                }
            } catch {
                healthKitSleepEnabled = false
            }
        }
    }
}

#Preview {
    SettingsView()
}
