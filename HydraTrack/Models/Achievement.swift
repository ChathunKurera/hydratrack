//
//  Achievement.swift
//  HydraTrack
//

import Foundation
import SwiftUI

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let customColors: (primary: Color, secondary: Color)?

    init(id: String, title: String, description: String, icon: String, category: AchievementCategory, customColors: (primary: Color, secondary: Color)? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.customColors = customColors
    }

    enum AchievementCategory: String {
        case streak = "Streaks"
        case volume = "Volume"
        case consistency = "Consistency"
        case milestone = "Milestones"
        case variety = "Variety"
        case timing = "Timing"
        case challenge = "Challenge"
    }
}

// All available achievements - lightweight, no storage needed
extension Achievement {
    static let all: [Achievement] = [
        // Streak Achievements
        Achievement(
            id: "streak_7",
            title: "Week Warrior",
            description: "Maintain a 7-day streak",
            icon: "flame.fill",
            category: .streak
        ),
        Achievement(
            id: "streak_30",
            title: "Month Master",
            description: "Maintain a 30-day streak",
            icon: "flame.circle.fill",
            category: .streak
        ),
        Achievement(
            id: "streak_100",
            title: "Century Club",
            description: "Maintain a 100-day streak",
            icon: "trophy.fill",
            category: .streak
        ),

        // Volume Achievements
        Achievement(
            id: "goal_120",
            title: "Overachiever",
            description: "Reach 120% of your daily goal",
            icon: "star.fill",
            category: .volume
        ),
        Achievement(
            id: "goal_120_5times",
            title: "Hydration Hero",
            description: "Reach 120%+ of goal 5 times",
            icon: "star.circle.fill",
            category: .volume
        ),
        Achievement(
            id: "single_day_3000",
            title: "Flood Warning",
            description: "Drink 3000mL in a single day",
            icon: "drop.triangle.fill",
            category: .volume
        ),

        // Consistency Achievements
        Achievement(
            id: "perfect_week",
            title: "Perfect Week",
            description: "Hit your goal every day for 7 days",
            icon: "calendar.badge.checkmark",
            category: .consistency
        ),
        Achievement(
            id: "early_bird_7",
            title: "Early Bird",
            description: "Log water within 30min of waking for 7 days",
            icon: "sunrise.fill",
            category: .consistency
        ),
        Achievement(
            id: "consistent_30",
            title: "Steady Flow",
            description: "Hit your goal 25 out of 30 days",
            icon: "chart.line.uptrend.xyaxis",
            category: .consistency
        ),

        // Milestone Achievements
        Achievement(
            id: "first_goal",
            title: "First Steps",
            description: "Complete your daily goal",
            icon: "checkmark.circle.fill",
            category: .milestone
        ),
        Achievement(
            id: "total_100L",
            title: "100 Liters",
            description: "Log 100L total hydration",
            icon: "waterbottle.fill",
            category: .milestone
        ),
        Achievement(
            id: "total_500L",
            title: "500 Liters",
            description: "Log 500L total hydration",
            icon: "drop.circle.fill",
            category: .milestone
        ),

        // Variety Achievements
        Achievement(
            id: "variety_pack",
            title: "Variety Pack",
            description: "Log 5 different drink types in a single day",
            icon: "square.grid.3x3.fill",
            category: .variety
        ),
        Achievement(
            id: "water_purist",
            title: "Water Purist",
            description: "Drink only water for 7 consecutive days",
            icon: "drop.halffull",
            category: .variety
        ),

        // Timing Achievements
        Achievement(
            id: "early_riser",
            title: "Early Riser",
            description: "Reach 500mL before 9 AM for 5 days",
            icon: "sun.horizon.fill",
            category: .timing
        ),
        Achievement(
            id: "halfway_hero",
            title: "Halfway Hero",
            description: "Reach 50% of daily goal before noon for 10 days",
            icon: "clock.badge.checkmark",
            category: .timing
        ),

        // Challenge Achievements
        Achievement(
            id: "weekend_warrior",
            title: "Weekend Warrior",
            description: "Hit goal on Saturday and Sunday for 4 consecutive weekends",
            icon: "calendar.badge.plus",
            category: .challenge
        ),
        Achievement(
            id: "marathon_month",
            title: "Marathon Month",
            description: "Complete your goal every day for 30 consecutive days",
            icon: "medal.fill",
            category: .challenge,
            customColors: (primary: Color(red: 1.0, green: 0.84, blue: 0), secondary: Color.black)
        ),
    ]
}
