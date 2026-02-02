//
//  Date+Extensions.swift
//  HydraTrack
//

import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}
