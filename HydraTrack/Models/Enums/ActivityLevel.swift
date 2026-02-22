//
//  ActivityLevel.swift
//  HydraTrack
//

import Foundation

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"

    nonisolated var bonus: Int {
        switch self {
        case .sedentary: return 0
        case .lightlyActive: return 350
        case .moderatelyActive: return 700
        case .veryActive: return 1000
        }
    }

    nonisolated var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "1-3 days/week"
        case .moderatelyActive: return "3-5 days/week"
        case .veryActive: return "6-7 days/week"
        }
    }

    nonisolated var shortName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Light"
        case .moderatelyActive: return "Moderate"
        case .veryActive: return "Active"
        }
    }
}
