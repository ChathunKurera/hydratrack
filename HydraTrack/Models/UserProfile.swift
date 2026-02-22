//
//  UserProfile.swift
//  HydraTrack
//

import Foundation
import SwiftData

@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var age: Int
    var weightKg: Double
    var gender: Gender
    var activityLevel: ActivityLevel
    var customGoalMl: Int?
    var createdAt: Date
    var updatedAt: Date

    init(age: Int, weightKg: Double, gender: Gender, activityLevel: ActivityLevel) {
        self.id = UUID()
        self.age = age
        self.weightKg = weightKg
        self.gender = gender
        self.activityLevel = activityLevel
        self.customGoalMl = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var calculatedGoalMl: Int {
        let baseRate = age >= 65 ? 25.0 : 30.0
        let base = baseRate * weightKg
        let activityBonus = Double(activityLevel.bonus)
        let total = Int(base + activityBonus)
        return min(max(total, 1500), 3200)
    }

    var dailyGoalMl: Int {
        customGoalMl ?? calculatedGoalMl
    }
}
