//
//  GoalAdjustmentSuggestion.swift
//  HydraTrack
//

import Foundation

struct GoalAdjustmentSuggestion {
    let type: AdjustmentType
    let currentGoal: Int
    let suggestedGoal: Int
    let reason: String
    let averageIntake: Int

    enum AdjustmentType {
        case increase
        case decrease
    }

    var changeAmount: Int {
        abs(suggestedGoal - currentGoal)
    }

    var changePercentage: Int {
        guard currentGoal > 0 else { return 0 }
        return (changeAmount * 100) / currentGoal
    }
}
