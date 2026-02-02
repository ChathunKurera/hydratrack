//
//  AchievementUnlock.swift
//  HydraTrack
//

import Foundation
import SwiftData

@Model
class AchievementUnlock {
    @Attribute(.unique) var achievementId: String
    var unlockedAt: Date
    var hasBeenSeen: Bool

    init(achievementId: String, unlockedAt: Date = Date()) {
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
        self.hasBeenSeen = false
    }
}
