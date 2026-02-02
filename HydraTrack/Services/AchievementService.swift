//
//  AchievementService.swift
//  HydraTrack
//

import Foundation
import SwiftData

class AchievementService {
    private let modelContext: ModelContext
    private let dataService: HydrationDataService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataService = HydrationDataService(modelContext: modelContext)
    }

    // MARK: - Check Achievements

    /// Checks for newly unlocked achievements and returns them
    func checkForNewAchievements() -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for achievement in Achievement.all {
            if !isUnlocked(achievementId: achievement.id) {
                if checkAchievement(achievement) {
                    unlockAchievement(achievement)
                    newlyUnlocked.append(achievement)
                }
            }
        }

        return newlyUnlocked
    }

    // MARK: - Achievement Checkers

    private func checkAchievement(_ achievement: Achievement) -> Bool {
        switch achievement.id {
        // Streak achievements
        case "streak_7":
            return dataService.getCurrentStreak() >= 7
        case "streak_30":
            return dataService.getCurrentStreak() >= 30
        case "streak_100":
            return dataService.getCurrentStreak() >= 100

        // Volume achievements
        case "goal_120":
            return checkGoalPercentage(minPercentage: 120, days: 1)
        case "goal_120_5times":
            return checkGoalPercentage(minPercentage: 120, days: 5)
        case "single_day_3000":
            return checkSingleDayVolume(minVolume: 3000)

        // Consistency achievements
        case "perfect_week":
            return checkPerfectWeek()
        case "early_bird_7":
            return checkEarlyBird(days: 7)
        case "consistent_30":
            return checkConsistency(requiredDays: 25, totalDays: 30)

        // Milestone achievements
        case "first_goal":
            return dataService.getCurrentStreak() >= 1
        case "total_100L":
            return getTotalHydration() >= 100_000
        case "total_500L":
            return getTotalHydration() >= 500_000

        // Variety achievements
        case "variety_pack":
            return checkVarietyPack()
        case "water_purist":
            return checkWaterPurist(days: 7)

        // Timing achievements
        case "early_riser":
            return checkEarlyRiser(days: 5)
        case "halfway_hero":
            return checkHalfwayHero(days: 10)

        // Challenge achievements
        case "weekend_warrior":
            return checkWeekendWarrior(weekends: 4)
        case "marathon_month":
            return checkMarathonMonth()

        default:
            return false
        }
    }

    // MARK: - Helper Methods

    private func checkGoalPercentage(minPercentage: Int, days: Int) -> Bool {
        let calendar = Calendar.current
        var count = 0

        for daysAgo in 0..<90 { // Check last 90 days
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
            let goal = dataService.getEffectiveGoal(for: date)

            let percentage = goal > 0 ? (totalIntake * 100) / goal : 0
            if percentage >= minPercentage {
                count += 1
                if count >= days {
                    return true
                }
            }
        }

        return false
    }

    private func checkSingleDayVolume(minVolume: Int) -> Bool {
        let calendar = Calendar.current

        for daysAgo in 0..<90 {
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

            if totalIntake >= minVolume {
                return true
            }
        }

        return false
    }

    private func checkPerfectWeek() -> Bool {
        let calendar = Calendar.current
        var consecutiveDays = 0

        for daysAgo in 0..<30 {
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
            let goal = dataService.getEffectiveGoal(for: date)

            if totalIntake >= goal {
                consecutiveDays += 1
                if consecutiveDays >= 7 {
                    return true
                }
            } else {
                consecutiveDays = 0
            }
        }

        return false
    }

    private func checkEarlyBird(days: Int) -> Bool {
        // Check if user logged water within 30min of wake time for specified days
        // For simplicity, check if first drink of day was before 8 AM
        let calendar = Calendar.current
        var earlyDays = 0

        for daysAgo in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let eightAM = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < eightAM
                },
                sortBy: [SortDescriptor(\.timestamp)]
            )

            let earlyDrinks = (try? modelContext.fetch(descriptor)) ?? []
            if !earlyDrinks.isEmpty {
                earlyDays += 1
                if earlyDays >= days {
                    return true
                }
            }
        }

        return false
    }

    private func checkConsistency(requiredDays: Int, totalDays: Int) -> Bool {
        let calendar = Calendar.current
        var goalMetDays = 0

        for daysAgo in 0..<totalDays {
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
            let goal = dataService.getEffectiveGoal(for: date)

            if totalIntake >= goal {
                goalMetDays += 1
            }
        }

        return goalMetDays >= requiredDays
    }

    private func getTotalHydration() -> Int {
        let descriptor = FetchDescriptor<DrinkEntry>()
        let allDrinks = (try? modelContext.fetch(descriptor)) ?? []
        return allDrinks.reduce(0) { $0 + $1.effectiveHydrationMl }
    }

    // MARK: - New Achievement Helpers

    private func checkVarietyPack() -> Bool {
        // Check if user logged 5 different drink types in a single day
        let calendar = Calendar.current

        for daysAgo in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let uniqueTypes = Set(drinks.map { $0.drinkType })

            if uniqueTypes.count >= 5 {
                return true
            }
        }

        return false
    }

    private func checkWaterPurist(days: Int) -> Bool {
        // Check if user drank only water for specified consecutive days
        let calendar = Calendar.current
        var consecutiveDays = 0

        for daysAgo in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []

            if drinks.isEmpty {
                consecutiveDays = 0
                continue
            }

            let allWater = drinks.allSatisfy { $0.drinkType == .water }

            if allWater {
                consecutiveDays += 1
                if consecutiveDays >= days {
                    return true
                }
            } else {
                consecutiveDays = 0
            }
        }

        return false
    }

    private func checkEarlyRiser(days: Int) -> Bool {
        // Check if user reached 500mL before 9 AM for specified days
        let calendar = Calendar.current
        var earlyDays = 0

        for daysAgo in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < nineAM
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let totalBefore9AM = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }

            if totalBefore9AM >= 500 {
                earlyDays += 1
                if earlyDays >= days {
                    return true
                }
            }
        }

        return false
    }

    private func checkHalfwayHero(days: Int) -> Bool {
        // Check if user reached 50% of goal before noon for specified days
        let calendar = Calendar.current
        var halfwayDays = 0

        for daysAgo in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!

            let descriptor = FetchDescriptor<DrinkEntry>(
                predicate: #Predicate { drink in
                    drink.timestamp >= startOfDay && drink.timestamp < noon
                }
            )

            let drinks = (try? modelContext.fetch(descriptor)) ?? []
            let totalBeforeNoon = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
            let goal = dataService.getEffectiveGoal(for: date)

            if goal > 0 && totalBeforeNoon >= (goal / 2) {
                halfwayDays += 1
                if halfwayDays >= days {
                    return true
                }
            }
        }

        return false
    }

    private func checkWeekendWarrior(weekends: Int) -> Bool {
        // Check if user hit goal on both Saturday and Sunday for specified consecutive weekends
        let calendar = Calendar.current
        var consecutiveWeekends = 0

        // Go back through weekends
        for weekAgo in 0..<12 {
            // Find the Saturday of that week
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekAgo, to: Date()) else { continue }

            // Get the Saturday (weekday 7 in Gregorian calendar)
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
            components.weekday = 7 // Saturday
            guard let saturday = calendar.date(from: components) else { continue }

            components.weekday = 1 // Sunday
            guard let sunday = calendar.date(from: components) else { continue }

            let saturdayMet = checkGoalMetForDate(saturday)
            let sundayMet = checkGoalMetForDate(sunday)

            if saturdayMet && sundayMet {
                consecutiveWeekends += 1
                if consecutiveWeekends >= weekends {
                    return true
                }
            } else {
                consecutiveWeekends = 0
            }
        }

        return false
    }

    private func checkMarathonMonth() -> Bool {
        // Check if user hit goal every day for 30 consecutive days
        let calendar = Calendar.current
        var consecutiveDays = 0

        for daysAgo in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }

            if checkGoalMetForDate(date) {
                consecutiveDays += 1
                if consecutiveDays >= 30 {
                    return true
                }
            } else {
                consecutiveDays = 0
            }
        }

        return false
    }

    private func checkGoalMetForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<DrinkEntry>(
            predicate: #Predicate { drink in
                drink.timestamp >= startOfDay && drink.timestamp < endOfDay
            }
        )

        let drinks = (try? modelContext.fetch(descriptor)) ?? []
        let totalIntake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
        let goal = dataService.getEffectiveGoal(for: date)

        return totalIntake >= goal
    }

    // MARK: - Unlock Management

    private func isUnlocked(achievementId: String) -> Bool {
        let descriptor = FetchDescriptor<AchievementUnlock>(
            predicate: #Predicate { unlock in
                unlock.achievementId == achievementId
            }
        )
        return (try? modelContext.fetch(descriptor).first) != nil
    }

    private func unlockAchievement(_ achievement: Achievement) {
        let unlock = AchievementUnlock(achievementId: achievement.id)
        modelContext.insert(unlock)
        try? modelContext.save()
    }

    func getUnlockedAchievements() -> [(Achievement, Date)] {
        let descriptor = FetchDescriptor<AchievementUnlock>(
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        let unlocks = (try? modelContext.fetch(descriptor)) ?? []

        return unlocks.compactMap { unlock in
            guard let achievement = Achievement.all.first(where: { $0.id == unlock.achievementId }) else {
                return nil
            }
            return (achievement, unlock.unlockedAt)
        }
    }

    func getNewAchievementCount() -> Int {
        let descriptor = FetchDescriptor<AchievementUnlock>(
            predicate: #Predicate { unlock in
                unlock.hasBeenSeen == false
            }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    func markAllAsSeen() {
        let descriptor = FetchDescriptor<AchievementUnlock>(
            predicate: #Predicate { unlock in
                unlock.hasBeenSeen == false
            }
        )
        let unseenUnlocks = (try? modelContext.fetch(descriptor)) ?? []
        unseenUnlocks.forEach { $0.hasBeenSeen = true }
        try? modelContext.save()
    }
}
