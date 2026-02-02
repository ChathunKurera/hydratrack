//
//  Gender.swift
//  HydraTrack
//

import Foundation

enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}
