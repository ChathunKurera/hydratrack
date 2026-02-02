//
//  InsightsCard.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct InsightsCard: View {
    @Environment(\.modelContext) private var modelContext

    @State private var weeklyInsights: WeeklyInsights?
    @State private var monthlyInsights: MonthlyInsights?
    @State private var tips: [InsightTip] = []
    @State private var showingDetail = false

    private var insightsService: InsightsService {
        InsightsService(modelContext: modelContext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Insights")
                    .font(.headline)

                Spacer()

                Button("See More") {
                    showingDetail = true
                }
                .font(.caption)
                .foregroundColor(.primaryBlue)
            }

            if let weekly = weeklyInsights {
                // Quick Stats
                HStack(spacing: 20) {
                    StatBubble(
                        icon: "chart.bar.fill",
                        value: "\(weekly.averageIntake)mL",
                        label: "Avg/Day"
                    )

                    StatBubble(
                        icon: "checkmark.circle.fill",
                        value: "\(weekly.completionRate)%",
                        label: "Goal Rate"
                    )

                    if weekly.comparedToLastWeek != 0 {
                        StatBubble(
                            icon: weekly.comparedToLastWeek > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                            value: "\(abs(weekly.comparedToLastWeek))%",
                            label: "vs Last Week",
                            color: weekly.comparedToLastWeek > 0 ? .green : .orange
                        )
                    }
                }

                // Tips
                if !tips.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(tips.prefix(2), id: \.message) { tip in
                            TipRow(tip: tip)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .onAppear {
            loadInsights()
        }
        .sheet(isPresented: $showingDetail) {
            InsightsDetailView()
        }
    }

    private func loadInsights() {
        weeklyInsights = insightsService.getWeeklyInsights()
        monthlyInsights = insightsService.getMonthlyInsights()

        if let weekly = weeklyInsights {
            tips = insightsService.generateInsightTips(weeklyInsights: weekly)
        }
    }
}

struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .primaryBlue

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TipRow: View {
    let tip: InsightTip

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tip.icon)
                .foregroundColor(tipColor)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(tip.message)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tipColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var tipColor: Color {
        switch tip.category {
        case .positive: return .green
        case .suggestion: return .blue
        case .warning: return .orange
        }
    }
}

struct InsightsDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var weeklyInsights: WeeklyInsights?
    @State private var monthlyInsights: MonthlyInsights?
    @State private var hourlyPatterns: [HourlyPattern] = []

    private var insightsService: InsightsService {
        InsightsService(modelContext: modelContext)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Weekly Section
                    if let weekly = weeklyInsights {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This Week")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(weekly.weekLabel)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            DetailRow(label: "Average Daily Intake", value: "\(weekly.averageIntake) mL")
                            DetailRow(label: "Total Volume", value: "\(weekly.totalVolume) mL")
                            DetailRow(label: "Days Goal Met", value: "\(weekly.daysGoalMet) / 7")
                            DetailRow(label: "Completion Rate", value: "\(weekly.completionRate)%")

                            if let bestDay = weekly.bestDay {
                                DetailRow(
                                    label: "Best Day",
                                    value: bestDayString(from: bestDay),
                                    highlight: true
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                    }

                    // Monthly Section
                    if let monthly = monthlyInsights {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This Month")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(monthly.monthLabel)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            DetailRow(label: "Average Daily Intake", value: "\(monthly.averageIntake) mL")
                            DetailRow(label: "Total Volume", value: String(format: "%.1fL", Double(monthly.totalVolume) / 1000))
                            DetailRow(label: "Days Goal Met", value: "\(monthly.daysGoalMet) days")
                            DetailRow(label: "Completion Rate", value: "\(monthly.completionRate)%")
                            DetailRow(label: "Longest Streak", value: "\(monthly.streakRecord) days", highlight: true)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                    }

                    // Hourly Pattern
                    if !hourlyPatterns.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Peak Hours")
                                .font(.title2)
                                .fontWeight(.bold)

                            let topHours = hourlyPatterns
                                .filter { $0.averageIntake > 0 }
                                .sorted { $0.averageIntake > $1.averageIntake }
                                .prefix(5)

                            ForEach(Array(topHours.enumerated()), id: \.offset) { index, pattern in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)

                                    Text(pattern.timeLabel)
                                        .font(.subheadline)

                                    Spacer()

                                    Text("\(pattern.averageIntake) mL avg")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Detailed Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadInsights()
            }
        }
    }

    private func loadInsights() {
        weeklyInsights = insightsService.getWeeklyInsights()
        monthlyInsights = insightsService.getMonthlyInsights()
        hourlyPatterns = insightsService.getHourlyPatterns()
    }

    private func bestDayString(from bestDay: (date: Date, intake: Int)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "\(formatter.string(from: bestDay.date)) (\(bestDay.intake)mL)"
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(highlight ? .semibold : .regular)
                .foregroundColor(highlight ? .primaryBlue : .primary)
        }
    }
}

#Preview {
    InsightsCard()
}
