//
//  VolumeUnit.swift
//  HydraTrack
//

import Foundation

enum VolumeUnit: String, CaseIterable, Sendable {
    case milliliters = "Metric"
    case ounces = "Freedom"

    var abbreviation: String {
        switch self {
        case .milliliters: return "mL"
        case .ounces: return "oz"
        }
    }

    func convert(from ml: Int) -> Double {
        switch self {
        case .milliliters: return Double(ml)
        case .ounces: return Double(ml) / 29.5735
        }
    }

    func convertToMl(from value: Double) -> Int {
        switch self {
        case .milliliters: return Int(value)
        case .ounces: return Int(value * 29.5735)
        }
    }

    func format(_ ml: Int) -> String {
        let converted = convert(from: ml)
        if self == .ounces {
            return String(format: "%.1f %@", converted, abbreviation)
        } else {
            return "\(Int(converted)) \(abbreviation)"
        }
    }
}
