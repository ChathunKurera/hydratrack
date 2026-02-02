//
//  NotificationManager.swift
//  HydraTrack
//

import Foundation
import Combine
import UserNotifications
import SwiftData

class NotificationManager: ObservableObject {
    private let center = UNUserNotificationCenter.current()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await checkAuthorizationStatus()
    }

    private func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
        }
    }

    // MARK: - Scheduling

    func scheduleReminders(wakeTime: Date, sleepTime: Date, frequency: Int) {
        cancelAllReminders()

        guard frequency > 0 else { return }

        let times = calculateReminderTimes(wake: wakeTime, sleep: sleepTime, count: frequency)

        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time to Hydrate!"
            content.body = "Remember to drink water to stay healthy."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "hydration-reminder-\(index)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    private func calculateReminderTimes(wake: Date, sleep: Date, count: Int) -> [Date] {
        var times: [Date] = []
        let calendar = Calendar.current

        let wakeMinutes = calendar.component(.hour, from: wake) * 60 + calendar.component(.minute, from: wake)
        let sleepMinutes = calendar.component(.hour, from: sleep) * 60 + calendar.component(.minute, from: sleep)

        let totalMinutes = sleepMinutes - wakeMinutes
        let interval = totalMinutes / (count + 1)

        for i in 1...count {
            let minutesFromMidnight = wakeMinutes + (interval * i)
            let hour = minutesFromMidnight / 60
            let minute = minutesFromMidnight % 60

            if let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                times.append(time)
            }
        }

        return times
    }

    // MARK: - Smart Reminders (Advanced)

    func scheduleSmartReminders(enabled: Bool, modelContext: ModelContext) {
        // Cancel existing smart reminders first
        center.removePendingNotificationRequests(withIdentifiers: getSmartReminderIdentifiers())

        guard enabled else {
            print("Smart reminders disabled")
            return
        }

        // Schedule smart suggestions
        scheduleInactivityReminder(modelContext: modelContext)
        scheduleProgressCheckReminder(modelContext: modelContext)
        schedulePatternBasedReminder(modelContext: modelContext)

        print("Smart reminders enabled and scheduled")
    }

    private func getSmartReminderIdentifiers() -> [String] {
        return [
            "smart-inactivity",
            "smart-progress-morning",
            "smart-progress-afternoon",
            "smart-progress-evening",
            "smart-pattern-morning",
            "smart-pattern-afternoon",
            "smart-pattern-evening"
        ]
    }

    // MARK: - Smart Suggestion Types

    private func scheduleInactivityReminder(modelContext: ModelContext) {
        // Check every 3 hours if user hasn't logged anything
        let content = UNMutableNotificationContent()
        content.title = "Time for Water?"
        content.body = "You haven't logged anything in a while. Stay hydrated!"
        content.sound = .default

        // Schedule for 3 hours from now, doesn't repeat
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 60 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "smart-inactivity",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func scheduleProgressCheckReminder(modelContext: ModelContext) {
        let dataService = HydrationDataService(modelContext: modelContext)
        let todayIntake = dataService.getTodayIntake()
        let dailyGoal = dataService.getEffectiveGoal()

        guard dailyGoal > 0 else { return }

        let progressPercentage = (todayIntake * 100) / dailyGoal

        // Morning check (10 AM)
        scheduleProgressNotification(
            identifier: "smart-progress-morning",
            hour: 10,
            progressPercentage: progressPercentage,
            timeOfDay: "morning"
        )

        // Afternoon check (2 PM)
        scheduleProgressNotification(
            identifier: "smart-progress-afternoon",
            hour: 14,
            progressPercentage: progressPercentage,
            timeOfDay: "afternoon"
        )

        // Evening check (6 PM)
        scheduleProgressNotification(
            identifier: "smart-progress-evening",
            hour: 18,
            progressPercentage: progressPercentage,
            timeOfDay: "evening"
        )
    }

    private func scheduleProgressNotification(identifier: String, hour: Int, progressPercentage: Int, timeOfDay: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Progress"

        if progressPercentage >= 80 {
            content.body = "You're at \(progressPercentage)% - you're crushing it!"
        } else if progressPercentage >= 50 {
            content.body = "You're at \(progressPercentage)% by \(timeOfDay) - you're on track!"
        } else if progressPercentage >= 25 {
            content.body = "You're at \(progressPercentage)% - let's pick up the pace!"
        } else {
            content.body = "Only \(progressPercentage)% so far - time to catch up!"
        }

        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func schedulePatternBasedReminder(modelContext: ModelContext) {
        let insightsService = InsightsService(modelContext: modelContext)
        let patterns = insightsService.getHourlyPatterns()

        // Find top 3 peak hours
        let topHours = patterns
            .filter { $0.averageIntake > 0 }
            .sorted { $0.averageIntake > $1.averageIntake }
            .prefix(3)

        for (index, pattern) in topHours.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Your Typical Hydration Time"
            content.body = "You typically drink around \(pattern.averageIntake)mL at \(pattern.timeLabel). Quick add?"
            content.sound = .default

            var components = DateComponents()
            components.hour = pattern.hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let identifier: String
            if pattern.hour < 12 {
                identifier = "smart-pattern-morning"
            } else if pattern.hour < 18 {
                identifier = "smart-pattern-afternoon"
            } else {
                identifier = "smart-pattern-evening"
            }

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    // MARK: - Helper Methods

    func checkLastDrinkTime(modelContext: ModelContext) -> Date? {
        let descriptor = FetchDescriptor<DrinkEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let drinks = try? modelContext.fetch(descriptor)
        return drinks?.first?.timestamp
    }

    func getTimeSinceLastDrink(modelContext: ModelContext) -> TimeInterval? {
        guard let lastDrink = checkLastDrinkTime(modelContext: modelContext) else {
            return nil
        }
        return Date().timeIntervalSince(lastDrink)
    }
}
