//
//  AppSettings.swift
//  HydraTrack
//

import Foundation
import SwiftUI

struct AppSettings {
    @AppStorage("units") var units: VolumeUnit = .milliliters
    @AppStorage("wakeTimeMinutes") var wakeTimeMinutes: Int = 420 // 7:00 AM
    @AppStorage("sleepTimeMinutes") var sleepTimeMinutes: Int = 1380 // 11:00 PM
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") var notificationFrequency: Int = 4
    @AppStorage("smartRemindersEnabled") var smartRemindersEnabled: Bool = false
    @AppStorage("smartReminderThresholdHours") var smartReminderThresholdHours: Int = 2
    @AppStorage("healthKitSleepEnabled") var healthKitSleepEnabled: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var wakeTime: Date {
        Calendar.current.date(bySettingHour: wakeTimeMinutes / 60,
                              minute: wakeTimeMinutes % 60,
                              second: 0,
                              of: Date()) ?? Date()
    }

    var sleepTime: Date {
        Calendar.current.date(bySettingHour: sleepTimeMinutes / 60,
                              minute: sleepTimeMinutes % 60,
                              second: 0,
                              of: Date()) ?? Date()
    }
}
