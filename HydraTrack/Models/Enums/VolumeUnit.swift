//
//  VolumeUnit.swift
//  HydraTrack
//

import Foundation

enum VolumeUnit: String, CaseIterable, Sendable {
    case milliliters = "Metric"
    case ounces = "Freedom"

    nonisolated func convert(from ml: Int) -> Double {
        switch self {
        case .milliliters: return Double(ml)
        case .ounces: return Double(ml) / 29.5735
        }
    }

    nonisolated func convertToMl(from value: Double) -> Int {
        switch self {
        case .milliliters: return Int(value)
        case .ounces: return Int(value * 29.5735)
        }
    }
}
