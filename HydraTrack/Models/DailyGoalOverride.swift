//
//  DailyGoalOverride.swift
//  HydraTrack
//

import Foundation
import SwiftData

@Model
class DailyGoalOverride {
    @Attribute(.unique) var id: UUID
    var date: Date // Start of day
    var goalMl: Int

    init(date: Date, goalMl: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.goalMl = goalMl
    }
}
