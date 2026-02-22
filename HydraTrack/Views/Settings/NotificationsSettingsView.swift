//
//  NotificationsSettingsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct NotificationsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") private var notificationFrequency: Int = 4
    @AppStorage("smartRemindersEnabled") private var smartRemindersEnabled: Bool = false
    @AppStorage("smartReminderThresholdHours") private var smartReminderThresholdHours: Int = 2
    @AppStorage("wakeTimeMinutes") private var wakeTimeMinutes: Int = 420
    @AppStorage("sleepTimeMinutes") private var sleepTimeMinutes: Int = 1380

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
            Section {
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
            } footer: {
                Text("Receive periodic reminders to stay hydrated throughout the day.")
            }

            if notificationsEnabled {
                Section("Frequency") {
                    Stepper("Reminders per day: \(notificationFrequency)", value: $notificationFrequency, in: 1...10)
                        .onChange(of: notificationFrequency) { _, _ in
                            scheduleNotifications()
                        }

                    Text("Reminders are spread evenly between your wake and sleep times.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Smart Reminders", isOn: $smartRemindersEnabled)
                        .onChange(of: smartRemindersEnabled) { _, newValue in
                            notificationManager.scheduleSmartReminders(enabled: newValue, modelContext: modelContext)
                        }

                    if smartRemindersEnabled {
                        Stepper("Check every \(smartReminderThresholdHours) hour\(smartReminderThresholdHours == 1 ? "" : "s")", value: $smartReminderThresholdHours, in: 1...6)
                    }
                } footer: {
                    Text("Smart reminders notify you when you haven't logged a drink for a while, regardless of the regular schedule.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationView {
        NotificationsSettingsView()
    }
}
