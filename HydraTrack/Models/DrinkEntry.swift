//
//  DrinkEntry.swift
//  HydraTrack
//

import Foundation
import SwiftData

@Model
class DrinkEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var volumeMl: Int
    var drinkType: DrinkType
    var effectiveHydrationMl: Int
    var name: String = "" // Actual drink name (e.g., "Cappuccino", "Gatorade")

    init(volumeMl: Int, drinkType: DrinkType, name: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.volumeMl = volumeMl
        self.drinkType = drinkType
        self.name = name ?? drinkType.rawValue // Default to drinkType name if not provided
        self.timestamp = timestamp
        self.effectiveHydrationMl = Int(Double(volumeMl) * drinkType.hydrationFactor)
    }
}
