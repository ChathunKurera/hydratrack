//
//  HydraTrackApp.swift
//  HydraTrack
//
//  Created by Chathun Kurera on 1/25/26.
//

import SwiftUI
import SwiftData

@main
struct HydraTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var healthKitManager = HealthKitManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            DrinkEntry.self,
            DailyGoalOverride.self,
            AchievementUnlock.self,
            GoalHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(healthKitManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
