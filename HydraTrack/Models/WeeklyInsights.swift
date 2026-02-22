//
//  WeeklyInsights.swift
//  HydraTrack
//

import Foundation

struct WeeklyInsights {
    let weekStart: Date
    let weekEnd: Date
    let averageIntake: Int
    let bestDay: (date: Date, intake: Int)?
    let worstDay: (date: Date, intake: Int)?
    let totalVolume: Int
    let daysGoalMet: Int
    let daysElapsed: Int  // How many days have passed (1-7)
    let completionRate: Int
    let comparedToLastWeek: Int // Percentage change

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
}

struct MonthlyInsights {
    let monthStart: Date
    let monthEnd: Date
    let averageIntake: Int
    let bestWeek: (weekStart: Date, avgIntake: Int)?
    let totalVolume: Int
    let daysGoalMet: Int
    let completionRate: Int
    let streakRecord: Int
    let comparedToLastMonth: Int // Percentage change

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthStart)
    }
}

struct HourlyPattern {
    let hour: Int
    let averageIntake: Int

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

struct InsightTip {
    let icon: String
    let message: String
    let category: TipCategory

    enum TipCategory {
        case positive
        case suggestion
        case warning
    }
}
