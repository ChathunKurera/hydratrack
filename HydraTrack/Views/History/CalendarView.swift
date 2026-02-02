//
//  CalendarView.swift
//  HydraTrack
//

import SwiftUI

struct CalendarView: View {
    let completionData: [Date: Int] // Date -> Completion percentage (0-100+)
    let currentStreak: Int

    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        let monthEnd = monthInterval.end

        var currentDate = monthFirstWeek.start

        while currentDate < monthEnd {
            let components = calendar.dateComponents([.month], from: currentMonth, to: currentDate)
            if components.month == 0 {
                days.append(currentDate)
            } else {
                days.append(nil)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // Pad to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        VStack(spacing: 20) {
            // Streak banner
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentStreak) Day\(currentStreak == 1 ? "" : "s")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if currentStreak > 0 {
                    Text("🎯")
                        .font(.largeTitle)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: currentStreak > 0 ? [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)] : [Color.gray.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)

            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primaryBlue)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primaryBlue)
                }
                .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
            }
            .padding(.horizontal)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(date: date, completionPercentage: completionData[calendar.startOfDay(for: date)] ?? 0)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation {
                currentMonth = newMonth
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let completionPercentage: Int

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > Date()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if completionPercentage >= 100 {
                // 100%+ completion - green circle
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.1))
                    )
            } else if completionPercentage >= 50 {
                // 50-99% completion - light blue/orange circle
                Circle()
                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.08))
                    )
            } else if isToday {
                // Today - blue outline
                Circle()
                    .stroke(Color.primaryBlue, lineWidth: 2)
            }

            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isFuture ? .gray.opacity(0.3) :
                    completionPercentage >= 100 ? .green :
                    completionPercentage >= 50 ? .orange :
                    isToday ? .primaryBlue :
                    .primary
                )
        }
        .frame(height: 44)
    }
}

#Preview {
    let sampleData: [Date: Int] = [
        Calendar.current.startOfDay(for: Date()): 100,
        Calendar.current.startOfDay(for: Date().daysAgo(1)): 100,
        Calendar.current.startOfDay(for: Date().daysAgo(2)): 75,
        Calendar.current.startOfDay(for: Date().daysAgo(3)): 30,
        Calendar.current.startOfDay(for: Date().daysAgo(4)): 100,
    ]

    return CalendarView(completionData: sampleData, currentStreak: 3)
        .padding()
}
