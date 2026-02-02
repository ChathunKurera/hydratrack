//
//  AppDelegate.swift
//  HydraTrack
//

import UIKit
import BackgroundTasks
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    static let backgroundTaskIdentifier = "com.hydratrack.smartreminder"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleSmartReminderTask(task: task as! BGAppRefreshTask)
        }

        // Schedule the first background task
        scheduleBackgroundTask()

        return true
    }

    // MARK: - Background Task Scheduling

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled successfully")
        } catch {
            print("Could not schedule background task: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Task Handler

    private func handleSmartReminderTask(task: BGAppRefreshTask) {
        // Schedule the next background task
        scheduleBackgroundTask()

        // Create a task to check if notification should be sent
        let taskComplete = Task {
            await checkAndSendSmartReminder()
        }

        // Set expiration handler
        task.expirationHandler = {
            taskComplete.cancel()
        }

        // Notify system when task is complete
        Task {
            await taskComplete.value
            task.setTaskCompleted(success: true)
        }
    }

    private func checkAndSendSmartReminder() async {
        let settings = AppSettings()

        // Check if smart reminders are enabled
        guard settings.smartRemindersEnabled else { return }

        // Check if notifications are enabled
        guard settings.notificationsEnabled else { return }

        // Get model container
        let schema = Schema([UserProfile.self, DrinkEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return
        }

        let modelContext = ModelContext(modelContainer)

        // Check last drink time
        let descriptor = FetchDescriptor<DrinkEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let drinks = try? modelContext.fetch(descriptor),
              let lastDrink = drinks.first else {
            // No drinks logged yet, send reminder
            await sendSmartReminder()
            return
        }

        // Calculate time since last drink
        let timeSinceLastDrink = Date().timeIntervalSince(lastDrink.timestamp)
        let thresholdSeconds = TimeInterval(settings.smartReminderThresholdHours * 3600)

        // Check if within wake window
        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        let wakeMinutes = settings.wakeTimeMinutes
        let sleepMinutes = settings.sleepTimeMinutes

        let isWithinWakeWindow = currentMinutes >= wakeMinutes && currentMinutes <= sleepMinutes

        // Send notification if threshold exceeded and within wake window
        if timeSinceLastDrink > thresholdSeconds && isWithinWakeWindow {
            await sendSmartReminder()
        }
    }

    private func sendSmartReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Hydration Check"
        content.body = "It's been a while since your last drink. Time to hydrate!"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "smart-reminder-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Smart reminder sent successfully")
        } catch {
            print("Error sending smart reminder: \(error.localizedDescription)")
        }
    }
}
