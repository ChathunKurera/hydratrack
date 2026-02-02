//
//  DrinkType.swift
//  HydraTrack
//

import Foundation

enum DrinkType: String, Codable, CaseIterable, Sendable {
    case water = "Water"
    case coffee = "Coffee"
    case tea = "Tea"
    case juice = "Juice"
    case milk = "Milk"
    case soda = "Soda"
    case other = "Other"

    nonisolated var hydrationFactor: Double {
        switch self {
        case .water: return 1.0
        case .coffee: return 0.85
        case .tea: return 0.95
        case .juice: return 0.9
        case .milk: return 0.9
        case .soda: return 0.8
        case .other: return 0.9
        }
    }

    nonisolated var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "mug.fill"
        case .juice: return "wineglass"
        case .milk: return "waterbottle.fill"
        case .soda: return "takeoutbag.and.cup.and.straw.fill"
        case .other: return "cup.and.saucer"
        }
    }
}
