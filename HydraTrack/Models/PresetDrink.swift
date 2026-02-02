//
//  PresetDrink.swift
//  HydraTrack
//

import Foundation

struct PresetDrink: Identifiable {
    let id = UUID()
    let name: String
    let volumeMl: Int
    let drinkType: DrinkType
    let icon: String

    var effectiveHydrationMl: Int {
        Int(Double(volumeMl) * drinkType.hydrationFactor)
    }
}
