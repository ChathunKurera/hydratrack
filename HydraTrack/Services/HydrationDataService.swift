//
//  HydrationDataService.swift
//  HydraTrack
//

import Foundation
import SwiftData

class HydrationDataService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Drink Operations

    func addDrink(volumeMl: Int, type: DrinkType, name: String? = nil) {
        let drink = DrinkEntry(volumeMl: volumeMl, drinkType: type, name: name)
        modelContext.insert(drink)
        try? modelContext.save()
    }

    func deleteDrink(_ drink: DrinkEntry) {
        modelContext.delete(drink)
        try? modelContext.save()
    }

    func getTodayIntake() -> Int {
        let drinks = getTodayDrinks()
        return drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
    }

    func getTodayDrinks() -> [DrinkEntry] {
        let startOfDay = Date().startOfDay
        let descriptor = FetchDescriptor<DrinkEntry>(
            predicate: #Predicate { drink in
                drink.timestamp >= startOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getLast7DaysIntake() -> [(Date, Int)] {
        var result: [(Date, Int)] = []
        let calendar = Calendar.current

        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let totalIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            result.append((startOfDay, totalIntake))
        }

        return result.reversed()
    }

    // MARK: - Profile Operations

    func getUserProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? modelContext.fetch(descriptor).first
    }

    func createUserProfile(age: Int, weightKg: Double, gender: Gender, activityLevel: ActivityLevel) -> UserProfile {
        let profile = UserProfile(age: age, weightKg: weightKg, gender: gender, activityLevel: activityLevel)
        modelContext.insert(profile)
        try? modelContext.save()

        // Record initial goal in history
        recordGoalHistory(goalMl: profile.dailyGoalMl, effectiveDate: Date())

        return profile
    }

    func updateUserProfile(_ profile: UserProfile) {
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    func setCustomGoal(_ goal: Int?, for profile: UserProfile) {
        let oldGoal = profile.dailyGoalMl
        profile.customGoalMl = goal
        updateUserProfile(profile)

        // Record goal history if the effective goal changed
        let newGoal = profile.dailyGoalMl
        if newGoal != oldGoal {
            recordGoalHistory(goalMl: newGoal, effectiveDate: Date())
        }
    }

    // MARK: - Daily Goal Overrides

    func setTodayGoalOverride(goalMl: Int) {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if override already exists for today
        let descriptor = FetchDescriptor<DailyGoalOverride>(
            predicate: #Predicate { override in
                override.date == today
            }
        )

        if let existingOverride = try? modelContext.fetch(descriptor).first {
            existingOverride.goalMl = goalMl
        } else {
            let override = DailyGoalOverride(date: today, goalMl: goalMl)
            modelContext.insert(override)
        }

        try? modelContext.save()
    }

    func getTodayGoalOverride() -> Int? {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyGoalOverride>(
            predicate: #Predicate { override in
                override.date == today
            }
        )

        return try? modelContext.fetch(descriptor).first?.goalMl
    }

    func clearTodayGoalOverride() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyGoalOverride>(
            predicate: #Predicate { override in
                override.date == today
            }
        )

        if let override = try? modelContext.fetch(descriptor).first {
            modelContext.delete(override)
            try? modelContext.save()
        }
    }

    func getEffectiveGoal(for date: Date = Date()) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)

        // First check for a daily override for this specific date
        let descriptor = FetchDescriptor<DailyGoalOverride>(
            predicate: #Predicate { override in
                override.date == startOfDay
            }
        )

        if let override = try? modelContext.fetch(descriptor).first {
            return override.goalMl
        }

        // For historical dates, look up the goal that was in effect on that date
        if let historicalGoal = getHistoricalGoal(for: date) {
            return historicalGoal
        }

        // Fall back to current profile goal (for dates before any history was recorded)
        return getUserProfile()?.dailyGoalMl ?? 2500
    }

    // MARK: - Completion & Streak Tracking

    func getCompletionData(for days: Int = 60) -> [Date: Int] {
        var result: [Date: Int] = [:]
        let calendar = Calendar.current

        for daysAgo in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let totalIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }

            let goal = getEffectiveGoal(for: date)
            let percentage = goal > 0 ? Int((Double(totalIntake) / Double(goal)) * 100) : 0
            result[startOfDay] = percentage
        }

        return result
    }

    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        // Check if today is complete, if not start from yesterday
        let todayIntake = getTodayIntake()
        let todayGoal = getEffectiveGoal(for: currentDate)

        if todayIntake < todayGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return 0
            }
            currentDate = yesterday
        }

        // Count backwards
        while true {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let totalIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            let goal = getEffectiveGoal(for: currentDate)

            if totalIntake >= goal {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                break
            }

            // Safety: don't go back more than 1 year
            if streak > 365 {
                break
            }
        }

        return streak
    }

    // MARK: - Dynamic Goal Adjustment

    func checkGoalAdjustment() -> GoalAdjustmentSuggestion? {
        let calendar = Calendar.current
        let currentGoal = getUserProfile()?.dailyGoalMl ?? 2500

        // First check for 7-day streak (increase suggestion takes priority as a reward)
        if let increaseSuggestion = checkForGoalIncrease(calendar: calendar, currentGoal: currentGoal) {
            return increaseSuggestion
        }

        // Then check for 3-day under-performance (decrease suggestion)
        if let decreaseSuggestion = checkForGoalDecrease(calendar: calendar, currentGoal: currentGoal) {
            return decreaseSuggestion
        }

        return nil
    }

    private func checkForGoalIncrease(calendar: Calendar, currentGoal: Int) -> GoalAdjustmentSuggestion? {
        // Check if user has met goal for 7 consecutive days
        var consecutiveDays = 0
        var totalIntakeSum = 0
        var totalExcess = 0

        for daysAgo in 1...7 { // Start from yesterday to avoid incomplete today
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let dayIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            let dayGoal = getEffectiveGoal(for: date)

            if dayIntake >= dayGoal {
                consecutiveDays += 1
                totalIntakeSum += dayIntake
                totalExcess += max(0, dayIntake - dayGoal)
            } else {
                break
            }
        }

        guard consecutiveDays >= 7 else { return nil }

        // Algorithm for increase:
        // - Base increase: 5%
        // - If average excess > 10% of goal, increase by 10%
        // - If average excess > 20% of goal, increase by 15%
        // - Cap at 15% increase and max goal of 4500mL

        let averageIntake = totalIntakeSum / 7
        let averageExcess = totalExcess / 7
        let excessPercentage = (averageExcess * 100) / currentGoal

        var increasePercentage: Int
        if excessPercentage > 20 {
            increasePercentage = 15
        } else if excessPercentage > 10 {
            increasePercentage = 10
        } else {
            increasePercentage = 5
        }

        let suggestedGoal = min(4500, currentGoal + (currentGoal * increasePercentage / 100))

        // Round to nearest 50mL
        let roundedGoal = ((suggestedGoal + 25) / 50) * 50

        // Don't suggest if already at max
        guard roundedGoal > currentGoal else { return nil }

        return GoalAdjustmentSuggestion(
            type: .increase,
            currentGoal: currentGoal,
            suggestedGoal: roundedGoal,
            reason: "You've crushed your goal 7 days in a row! Time to level up?",
            averageIntake: averageIntake
        )
    }

    private func checkForGoalDecrease(calendar: Calendar, currentGoal: Int) -> GoalAdjustmentSuggestion? {
        // Check if user has been under 75% for 3 consecutive days
        var consecutiveUnderDays = 0
        var totalIntakeSum = 0

        for daysAgo in 1...3 { // Start from yesterday
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let dayIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            let dayGoal = getEffectiveGoal(for: date)

            let percentage = dayGoal > 0 ? (dayIntake * 100) / dayGoal : 0

            if percentage < 75 && dayIntake > 0 { // Only count if they logged something
                consecutiveUnderDays += 1
                totalIntakeSum += dayIntake
            } else {
                break
            }
        }

        guard consecutiveUnderDays >= 3 else { return nil }

        // Algorithm for decrease:
        // Set new goal so that their average intake = 90% of new goal
        // This gives them a realistic target they can hit while building habits

        let averageIntake = totalIntakeSum / 3

        // New goal = average intake / 0.9 (so average = 90% of new goal)
        var suggestedGoal = Int(Double(averageIntake) / 0.9)

        // Round to nearest 50mL
        suggestedGoal = ((suggestedGoal + 25) / 50) * 50

        // Ensure minimum of 1500mL
        suggestedGoal = max(1500, suggestedGoal)

        // Don't suggest if not actually lower
        guard suggestedGoal < currentGoal else { return nil }

        return GoalAdjustmentSuggestion(
            type: .decrease,
            currentGoal: currentGoal,
            suggestedGoal: suggestedGoal,
            reason: "Your intake has been below 75% for 3 days. Let's set a more achievable target!",
            averageIntake: averageIntake
        )
    }

    func applyGoalAdjustment(newGoal: Int) {
        guard let profile = getUserProfile() else { return }
        profile.customGoalMl = newGoal
        updateUserProfile(profile)

        // Record the new goal in history (effective from today)
        recordGoalHistory(goalMl: newGoal, effectiveDate: Date())
    }

    // MARK: - Goal History

    func ensureGoalHistoryExists() {
        // Check if any goal history exists
        let descriptor = FetchDescriptor<GoalHistory>()
        let existingHistory = (try? modelContext.fetch(descriptor)) ?? []

        // If no history exists but user has a profile, create initial entry
        if existingHistory.isEmpty, let profile = getUserProfile() {
            // Use the earliest drink date as the effective date, or today if no drinks
            let drinkDescriptor = FetchDescriptor<DrinkEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            let earliestDrink = try? modelContext.fetch(drinkDescriptor).first
            let effectiveDate = earliestDrink?.timestamp ?? profile.createdAt

            recordGoalHistory(goalMl: profile.dailyGoalMl, effectiveDate: effectiveDate)
        }
    }

    private func recordGoalHistory(goalMl: Int, effectiveDate: Date) {
        let startOfDay = Calendar.current.startOfDay(for: effectiveDate)

        // Check if we already have an entry for this date
        let descriptor = FetchDescriptor<GoalHistory>(
            predicate: #Predicate { history in
                history.effectiveDate == startOfDay
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            // Update existing entry
            existing.goalMl = goalMl
        } else {
            // Create new entry
            let history = GoalHistory(effectiveDate: effectiveDate, goalMl: goalMl)
            modelContext.insert(history)
        }

        try? modelContext.save()
    }

    private func getHistoricalGoal(for date: Date) -> Int? {
        let startOfDay = Calendar.current.startOfDay(for: date)

        // Find the most recent goal history entry on or before this date
        let descriptor = FetchDescriptor<GoalHistory>(
            predicate: #Predicate { history in
                history.effectiveDate <= startOfDay
            },
            sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
        )

        return try? modelContext.fetch(descriptor).first?.goalMl
    }
}
