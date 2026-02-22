//
//  InsightsService.swift
//  HydraTrack
//

import Foundation
import SwiftData

class InsightsService {
    private let modelContext: ModelContext
    private let dataService: HydrationDataService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataService = HydrationDataService(modelContext: modelContext)
    }

    // MARK: - Weekly Insights

    func getWeeklyInsights(weeksAgo: Int = 0) -> WeeklyInsights? {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()) else { return nil }
        let weekStartDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDay)!

        // Calculate how many days have elapsed in this week (for current week only)
        let today = calendar.startOfDay(for: Date())
        let daysElapsed: Int
        if weeksAgo == 0 {
            // Current week: count days from week start up to and including today
            let daysSinceStart = calendar.dateComponents([.day], from: weekStartDay, to: today).day ?? 0
            daysElapsed = min(daysSinceStart + 1, 7) // +1 because we include today
        } else {
            // Past weeks: all 7 days
            daysElapsed = 7
        }

        var dailyIntakes: [(Date, Int)] = []
        var totalVolume = 0
        var daysGoalMet = 0

        // Only iterate through days that have elapsed
        for dayOffset in 0..<daysElapsed {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDay) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let intake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }

            dailyIntakes.append((date, intake))
            totalVolume += intake

            let goal = dataService.getEffectiveGoal(for: date)
            if intake >= goal {
                daysGoalMet += 1
            }
        }

        let averageIntake = dailyIntakes.isEmpty ? 0 : totalVolume / dailyIntakes.count
        let bestDay = dailyIntakes.max(by: { $0.1 < $1.1 })
        let worstDay = dailyIntakes.min(by: { $0.1 < $1.1 })
        let completionRate = daysElapsed > 0 ? (daysGoalMet * 100) / daysElapsed : 0

        // Compare to last week
        let lastWeekInsights = weeksAgo == 0 ? getWeeklyInsights(weeksAgo: 1) : nil
        let comparedToLastWeek: Int
        if let lastWeek = lastWeekInsights, lastWeek.averageIntake > 0 {
            comparedToLastWeek = ((averageIntake - lastWeek.averageIntake) * 100) / lastWeek.averageIntake
        } else {
            comparedToLastWeek = 0
        }

        return WeeklyInsights(
            weekStart: weekStartDay,
            weekEnd: weekEnd,
            averageIntake: averageIntake,
            bestDay: bestDay,
            worstDay: worstDay,
            totalVolume: totalVolume,
            daysGoalMet: daysGoalMet,
            daysElapsed: daysElapsed,
            completionRate: completionRate,
            comparedToLastWeek: comparedToLastWeek
        )
    }

    // MARK: - Monthly Insights

    func getMonthlyInsights(monthsAgo: Int = 0) -> MonthlyInsights? {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(byAdding: .month, value: -monthsAgo, to: Date()) else { return nil }
        let monthStartDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStartDay)!
        let daysInMonth = calendar.dateComponents([.day], from: monthStartDay, to: monthEnd).day ?? 30

        var totalVolume = 0
        var daysGoalMet = 0
        var maxStreak = 0
        var currentStreak = 0

        for dayOffset in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStartDay) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let intake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            totalVolume += intake

            let goal = dataService.getEffectiveGoal(for: date)
            if intake >= goal {
                daysGoalMet += 1
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        let averageIntake = daysInMonth > 0 ? totalVolume / daysInMonth : 0
        let completionRate = daysInMonth > 0 ? (daysGoalMet * 100) / daysInMonth : 0

        // Find best week
        var bestWeek: (weekStart: Date, avgIntake: Int)? = nil
        for weekOffset in 0...4 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: monthStartDay) else { continue }
            if let weekInsights = getWeeklyInsights(weeksAgo: weekOffset + (monthsAgo * 4)) {
                if let current = bestWeek {
                    if weekInsights.averageIntake > current.avgIntake {
                        bestWeek = (weekStart, weekInsights.averageIntake)
                    }
                } else {
                    bestWeek = (weekStart, weekInsights.averageIntake)
                }
            }
        }

        // Compare to last month
        let lastMonthInsights = monthsAgo == 0 ? getMonthlyInsights(monthsAgo: 1) : nil
        let comparedToLastMonth: Int
        if let lastMonth = lastMonthInsights, lastMonth.averageIntake > 0 {
            comparedToLastMonth = ((averageIntake - lastMonth.averageIntake) * 100) / lastMonth.averageIntake
        } else {
            comparedToLastMonth = 0
        }

        return MonthlyInsights(
            monthStart: monthStartDay,
            monthEnd: monthEnd,
            averageIntake: averageIntake,
            bestWeek: bestWeek,
            totalVolume: totalVolume,
            daysGoalMet: daysGoalMet,
            completionRate: completionRate,
            streakRecord: maxStreak,
            comparedToLastMonth: comparedToLastMonth
        )
    }

    // MARK: - Hourly Patterns

    func getHourlyPatterns() -> [HourlyPattern] {
        let calendar = Calendar.current
        var hourlyData: [Int: [Int]] = [:] // hour -> [intakes]

        // Analyze last 30 days
        for daysAgo in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                },
                sortBy: [SortDescriptor(\.timestamp)]
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []

            for drink in drinks {
                let hour = calendar.component(.hour, from: drink.timestamp)
                hourlyData[hour, default: []].append(drink.effectiveHydrationMl)
            }
        }

        return (0...23).map { hour in
            let intakes = hourlyData[hour] ?? []
            let average = intakes.isEmpty ? 0 : intakes.reduce(0, +) / intakes.count
            return HourlyPattern(hour: hour, averageIntake: average)
        }
    }

    // MARK: - Insight Tips

    func generateInsightTips(weeklyInsights: WeeklyInsights) -> [InsightTip] {
        var tips: [InsightTip] = []

        // Completion rate tips
        if weeklyInsights.completionRate >= 90 {
            tips.append(InsightTip(
                icon: "star.fill",
                message: "Amazing! You hit your goal \(weeklyInsights.daysGoalMet) out of \(weeklyInsights.daysElapsed) days this week!",
                category: .positive
            ))
        } else if weeklyInsights.completionRate < 50 {
            tips.append(InsightTip(
                icon: "exclamationmark.triangle.fill",
                message: "Only \(weeklyInsights.completionRate)% completion so far this week. Let's aim higher!",
                category: .warning
            ))
        }

        // Trend comparison
        if weeklyInsights.comparedToLastWeek > 10 {
            tips.append(InsightTip(
                icon: "arrow.up.circle.fill",
                message: "You're drinking \(weeklyInsights.comparedToLastWeek)% more than last week!",
                category: .positive
            ))
        } else if weeklyInsights.comparedToLastWeek < -10 {
            tips.append(InsightTip(
                icon: "arrow.down.circle.fill",
                message: "Your intake dropped \(abs(weeklyInsights.comparedToLastWeek))% from last week",
                category: .suggestion
            ))
        }

        // Best day recognition
        if let bestDay = weeklyInsights.bestDay {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let dayName = formatter.string(from: bestDay.date)

            tips.append(InsightTip(
                icon: "trophy.fill",
                message: "\(dayName) was your best day with \(bestDay.intake)mL!",
                category: .positive
            ))
        }

        // Hourly patterns
        let patterns = getHourlyPatterns()
        let peakHour = patterns.max(by: { $0.averageIntake < $1.averageIntake })
        if let peak = peakHour, peak.averageIntake > 0 {
            tips.append(InsightTip(
                icon: "clock.fill",
                message: "You typically drink most around \(peak.timeLabel)",
                category: .suggestion
            ))
        }

        return tips
    }
}
