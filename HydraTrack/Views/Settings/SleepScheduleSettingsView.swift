//
//  SleepScheduleSettingsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct SleepScheduleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @AppStorage("wakeTimeMinutes") private var wakeTimeMinutes: Int = 420
    @AppStorage("sleepTimeMinutes") private var sleepTimeMinutes: Int = 1380
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") private var notificationFrequency: Int = 4
    @AppStorage("healthKitSleepEnabled") private var healthKitSleepEnabled: Bool = false

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var wakeTime: Date {
        Calendar.current.date(bySettingHour: wakeTimeMinutes / 60, minute: wakeTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private var sleepTime: Date {
        Calendar.current.date(bySettingHour: sleepTimeMinutes / 60, minute: sleepTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        Form {
            if healthKitManager.isHealthKitAvailable() {
                Section {
                    Toggle("Use Apple Health", isOn: $healthKitSleepEnabled)
                        .onChange(of: healthKitSleepEnabled) { _, newValue in
                            if newValue {
                                requestHealthKitAccess()
                            } else {
                                healthKitManager.sleepSchedule = nil
                            }
                        }
                } footer: {
                    Text("Sync your sleep schedule from Apple Health to automatically adjust reminder times.")
                }
            }

            Section("Schedule") {
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
                } else {
                    HStack {
                        Text("Loading from Health...")
                            .foregroundColor(.secondary)
                        Spacer()
                        ProgressView()
                    }
                }
            }

            Section {
                HStack {
                    Text("Active Hours")
                    Spacer()
                    Text(activeHoursSummary)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Reminders will only be sent during your active hours.")
            }
        }
        .navigationTitle("Sleep Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var activeHoursSummary: String {
        let wakeHour = wakeTimeMinutes / 60
        let sleepHour = sleepTimeMinutes / 60
        var hours = sleepHour - wakeHour
        if hours < 0 { hours += 24 }
        return "\(hours) hours"
    }

    private func scheduleNotifications() {
        guard notificationsEnabled else { return }
        let lastDrinkTime = dataService.getTodayDrinks().first?.timestamp
        notificationManager.scheduleReminders(
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            frequency: notificationFrequency,
            lastDrinkTime: lastDrinkTime
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
    NavigationView {
        SleepScheduleSettingsView()
    }
}
