//
//  GoalHistory.swift
//  HydraTrack
//

import Foundation
import SwiftData

@Model
class GoalHistory {
    var effectiveDate: Date
    var goalMl: Int
    var createdAt: Date

    init(effectiveDate: Date, goalMl: Int) {
        self.effectiveDate = Calendar.current.startOfDay(for: effectiveDate)
        self.goalMl = goalMl
        self.createdAt = Date()
    }
}
