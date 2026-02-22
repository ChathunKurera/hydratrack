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

    // Minimum hours since last drink before sending a reminder
    static let minimumHoursSinceLastDrink: Double = 4.0

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

    func scheduleReminders(wakeTime: Date, sleepTime: Date, frequency: Int, lastDrinkTime: Date? = nil) {
        cancelAllReminders()

        guard frequency > 0 else { return }

        let times = calculateReminderTimes(wake: wakeTime, sleep: sleepTime, count: frequency)
        let calendar = Calendar.current
        let now = Date()

        // Calculate the cutoff time (4 hours after last drink)
        let cutoffTime: Date?
        if let lastDrink = lastDrinkTime {
            cutoffTime = lastDrink.addingTimeInterval(Self.minimumHoursSinceLastDrink * 60 * 60)
        } else {
            cutoffTime = nil
        }

        for (index, time) in times.enumerated() {
            // Get today's version of this reminder time
            var todayTime = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                          minute: calendar.component(.minute, from: time),
                                          second: 0, of: now)!

            // If this time has already passed today, consider tomorrow's occurrence
            if todayTime < now {
                todayTime = calendar.date(byAdding: .day, value: 1, to: todayTime)!
            }

            // Skip this notification if it's within 4 hours of the last drink
            if let cutoff = cutoffTime, todayTime < cutoff {
                print("Skipping reminder at \(time) - within 4 hours of last drink")
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Time to Hydrate!"
            content.body = getRandomReminderMessage()
            content.sound = .default

            let components = calendar.dateComponents([.hour, .minute], from: time)
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

    private func getRandomReminderMessage() -> String {
        let messages = [
            "Remember to drink water to stay healthy.",
            "Your body needs water! Take a sip.",
            "Staying hydrated helps you feel energized.",
            "A glass of water can boost your focus.",
            "Don't forget to hydrate!",
            "Water break time! Your body will thank you."
        ]
        return messages.randomElement() ?? messages[0]
    }

    /// Call this method whenever a drink is logged to refresh notification schedule
    func refreshNotificationsAfterDrink(wakeTime: Date, sleepTime: Date, frequency: Int, lastDrinkTime: Date) {
        scheduleReminders(wakeTime: wakeTime, sleepTime: sleepTime, frequency: frequency, lastDrinkTime: lastDrinkTime)
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

        // Check last drink time - don't schedule if recent
        let lastDrinkTime = checkLastDrinkTime(modelContext: modelContext)
        if let lastDrink = lastDrinkTime {
            let hoursSinceLastDrink = Date().timeIntervalSince(lastDrink) / 3600
            if hoursSinceLastDrink < Self.minimumHoursSinceLastDrink {
                print("Smart reminders: Last drink was \(String(format: "%.1f", hoursSinceLastDrink)) hours ago, scheduling for later")
            }
        }

        // Schedule smart suggestions
        scheduleInactivityReminder(modelContext: modelContext, lastDrinkTime: lastDrinkTime)
        scheduleProgressCheckReminder(modelContext: modelContext, lastDrinkTime: lastDrinkTime)
        schedulePatternBasedReminder(modelContext: modelContext, lastDrinkTime: lastDrinkTime)

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

    private func scheduleInactivityReminder(modelContext: ModelContext, lastDrinkTime: Date?) {
        // Schedule reminder for 4 hours after last drink, or 4 hours from now if no drinks
        let baseTime = lastDrinkTime ?? Date()
        let reminderTime = baseTime.addingTimeInterval(Self.minimumHoursSinceLastDrink * 60 * 60)

        // If the reminder time is in the past, schedule for 4 hours from now
        let actualReminderTime = reminderTime > Date() ? reminderTime : Date().addingTimeInterval(Self.minimumHoursSinceLastDrink * 60 * 60)

        let content = UNMutableNotificationContent()
        content.title = "Time for Water?"
        content.body = "You haven't logged anything in a while. Stay hydrated!"
        content.sound = .default

        let timeInterval = actualReminderTime.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(
            identifier: "smart-inactivity",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func scheduleProgressCheckReminder(modelContext: ModelContext, lastDrinkTime: Date?) {
        let dataService = HydrationDataService(modelContext: modelContext)
        let todayIntake = dataService.getTodayIntake()
        let dailyGoal = dataService.getEffectiveGoal()

        guard dailyGoal > 0 else { return }

        let progressPercentage = (todayIntake * 100) / dailyGoal

        // Calculate cutoff time (4 hours after last drink)
        let cutoffTime: Date?
        if let lastDrink = lastDrinkTime {
            cutoffTime = lastDrink.addingTimeInterval(Self.minimumHoursSinceLastDrink * 60 * 60)
        } else {
            cutoffTime = nil
        }

        // Morning check (10 AM)
        scheduleProgressNotification(
            identifier: "smart-progress-morning",
            hour: 10,
            progressPercentage: progressPercentage,
            timeOfDay: "morning",
            cutoffTime: cutoffTime
        )

        // Afternoon check (2 PM)
        scheduleProgressNotification(
            identifier: "smart-progress-afternoon",
            hour: 14,
            progressPercentage: progressPercentage,
            timeOfDay: "afternoon",
            cutoffTime: cutoffTime
        )

        // Evening check (6 PM)
        scheduleProgressNotification(
            identifier: "smart-progress-evening",
            hour: 18,
            progressPercentage: progressPercentage,
            timeOfDay: "evening",
            cutoffTime: cutoffTime
        )
    }

    private func scheduleProgressNotification(identifier: String, hour: Int, progressPercentage: Int, timeOfDay: String, cutoffTime: Date?) {
        let calendar = Calendar.current
        let now = Date()

        // Get today's version of this time
        var notificationTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!

        // If this time has passed today, schedule for tomorrow
        if notificationTime < now {
            notificationTime = calendar.date(byAdding: .day, value: 1, to: notificationTime)!
        }

        // Skip if within 4 hours of last drink
        if let cutoff = cutoffTime, notificationTime < cutoff {
            print("Skipping progress notification at \(hour):00 - within 4 hours of last drink")
            return
        }

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

    private func schedulePatternBasedReminder(modelContext: ModelContext, lastDrinkTime: Date?) {
        let insightsService = InsightsService(modelContext: modelContext)
        let patterns = insightsService.getHourlyPatterns()
        let calendar = Calendar.current
        let now = Date()

        // Calculate cutoff time
        let cutoffTime: Date?
        if let lastDrink = lastDrinkTime {
            cutoffTime = lastDrink.addingTimeInterval(Self.minimumHoursSinceLastDrink * 60 * 60)
        } else {
            cutoffTime = nil
        }

        // Find top 3 peak hours
        let topHours = patterns
            .filter { $0.averageIntake > 0 }
            .sorted { $0.averageIntake > $1.averageIntake }
            .prefix(3)

        for (_, pattern) in topHours.enumerated() {
            // Check if this hour's notification would be within 4 hours of last drink
            var notificationTime = calendar.date(bySettingHour: pattern.hour, minute: 0, second: 0, of: now)!
            if notificationTime < now {
                notificationTime = calendar.date(byAdding: .day, value: 1, to: notificationTime)!
            }

            if let cutoff = cutoffTime, notificationTime < cutoff {
                print("Skipping pattern notification at \(pattern.hour):00 - within 4 hours of last drink")
                continue
            }

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

    private func checkLastDrinkTime(modelContext: ModelContext) -> Date? {
        let descriptor = FetchDescriptor<DrinkEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let drinks = try? modelContext.fetch(descriptor)
        return drinks?.first?.timestamp
    }
}
