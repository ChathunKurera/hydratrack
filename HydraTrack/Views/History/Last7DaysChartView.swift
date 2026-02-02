//
//  Last7DaysChartView.swift
//  HydraTrack
//

import SwiftUI
import Charts

struct Last7DaysChartView: View {
    let data: [(Date, Int)]
    let goal: Int

    private var chartData: [DayIntake] {
        data.map { DayIntake(date: $0.0, intake: $0.1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Last 7 Days")
                .font(.headline)

            Chart {
                // Goal line
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                // Bar chart for daily intake
                ForEach(chartData) { dayIntake in
                    BarMark(
                        x: .value("Day", dayIntake.date, unit: .day),
                        y: .value("Intake", dayIntake.intake)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primaryBlue, .accentWater],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue / 1000)L")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Statistics
            HStack(spacing: 20) {
                StatBox(title: "Average", value: "\(averageIntake) mL", color: .blue)
                StatBox(title: "Highest", value: "\(maxIntake) mL", color: .green)
                StatBox(title: "Lowest", value: "\(minIntake) mL", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }

    private var averageIntake: Int {
        let total = data.reduce(0) { $0 + $1.1 }
        return data.isEmpty ? 0 : total / data.count
    }

    private var maxIntake: Int {
        data.map { $0.1 }.max() ?? 0
    }

    private var minIntake: Int {
        data.map { $0.1 }.min() ?? 0
    }
}

struct DayIntake: Identifiable {
    let id = UUID()
    let date: Date
    let intake: Int
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    let sampleData: [(Date, Int)] = [
        (Date().daysAgo(6), 2100),
        (Date().daysAgo(5), 2400),
        (Date().daysAgo(4), 1800),
        (Date().daysAgo(3), 2600),
        (Date().daysAgo(2), 2200),
        (Date().daysAgo(1), 2500),
        (Date(), 1900)
    ]

    return Last7DaysChartView(data: sampleData, goal: 2500)
        .padding()
}
