//
//  WeeklySummaryCard.swift
//  HydraTrack
//

import SwiftUI

struct WeeklySummaryCard: View {
    let insights: WeeklyInsights
    let dailyData: [(date: Date, percentage: Int)]

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.subheadline)
                .fontWeight(.semibold)

            // 7-day dot grid
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    if index < dailyData.count {
                        let data = dailyData[index]
                        let isToday = calendar.isDateInToday(data.date)
                        let isFuture = data.date > Date()

                        VStack(spacing: 4) {
                            dayLabel(for: data.date)

                            ZStack {
                                Circle()
                                    .fill(dotColor(percentage: data.percentage, isFuture: isFuture))
                                    .frame(width: 28, height: 28)

                                if isToday {
                                    Circle()
                                        .stroke(Color.primaryBlue, lineWidth: 2)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Bottom stats row
            HStack {
                Text("\(insights.daysGoalMet)/\(insights.daysElapsed) days")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if insights.comparedToLastWeek != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: insights.comparedToLastWeek > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text("\(abs(insights.comparedToLastWeek))% vs last week")
                            .font(.caption)
                    }
                    .foregroundColor(insights.comparedToLastWeek > 0 ? .green : .orange)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal)
    }

    private func dayLabel(for date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let label = String(formatter.string(from: date).prefix(1))

        return Text(label)
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    private func dotColor(percentage: Int, isFuture: Bool) -> Color {
        if isFuture { return Color.gray.opacity(0.2) }
        if percentage == 0 { return Color.gray.opacity(0.2) }
        if percentage >= 100 { return .green }
        if percentage >= 50 { return .orange }
        return Color.primaryBlue.opacity(0.5)
    }
}
