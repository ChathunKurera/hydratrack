//
//  GoalBreakdown.swift
//  HydraTrack
//

import Foundation

struct GoalBreakdown {
    let baseCalculation: String
    let baseAmount: Int
    let activityBonus: Int
    let totalBeforeClamp: Int
    let finalGoal: Int
    let wasClamped: Bool
}
