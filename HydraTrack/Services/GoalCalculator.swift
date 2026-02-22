//
//  GoalCalculator.swift
//  HydraTrack
//

import Foundation

struct GoalCalculator {
    static func getBreakdown(age: Int, weightKg: Double, activityLevel: ActivityLevel) -> GoalBreakdown {
        let baseRate = age >= 65 ? 25.0 : 30.0
        let base = baseRate * weightKg
        let baseAmount = Int(base)
        let activityBonus = activityLevel.bonus
        let totalBeforeClamp = baseAmount + activityBonus
        let finalGoal = min(max(totalBeforeClamp, 1500), 3200)
        let wasClamped = totalBeforeClamp != finalGoal

        let baseCalculation = "\(Int(baseRate)) mL × \(Int(weightKg)) kg"

        return GoalBreakdown(
            baseCalculation: baseCalculation,
            baseAmount: baseAmount,
            activityBonus: activityBonus,
            totalBeforeClamp: totalBeforeClamp,
            finalGoal: finalGoal,
            wasClamped: wasClamped
        )
    }
}
