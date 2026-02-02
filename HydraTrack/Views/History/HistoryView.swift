//
//  HistoryView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDrinks: [DrinkEntry]

    @State private var cachedProfile: UserProfile?
    @State private var cachedTodayIntake: Int = 0
    @State private var cachedLast7Days: [(Date, Int)] = []
    @State private var cachedCompletionData: [Date: Int] = [:]
    @State private var cachedStreak: Int = 0

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var userProfile: UserProfile? {
        cachedProfile ?? dataService.getUserProfile()
    }

    private var dailyGoal: Int {
        dataService.getEffectiveGoal()
    }

    private var todayIntake: Int {
        cachedTodayIntake
    }

    private var last7DaysData: [(Date, Int)] {
        cachedLast7Days
    }

    private var completionData: [Date: Int] {
        cachedCompletionData
    }

    private var currentStreak: Int {
        cachedStreak
    }

    private func updateCache() {
        cachedProfile = dataService.getUserProfile()
        cachedTodayIntake = dataService.getTodayIntake()
        cachedLast7Days = dataService.getLast7DaysIntake()
        cachedCompletionData = dataService.getCompletionData(for: 60)
        cachedStreak = dataService.getCurrentStreak()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Intake Card
                    TodayIntakeCard(intake: todayIntake, goal: dailyGoal)
                        .padding(.horizontal)
                        .padding(.top)

                    // Insights Card
                    InsightsCard()
                        .padding(.horizontal)

                    // Calendar View with Streak
                    CalendarView(completionData: completionData, currentStreak: currentStreak)
                        .padding(.horizontal)

                    // Last 7 Days Chart
                    Last7DaysChartView(data: last7DaysData, goal: dailyGoal)
                        .padding(.horizontal)

                    // Daily breakdown
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Daily Breakdown")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(last7DaysData.reversed(), id: \.0) { day in
                            DayBreakdownRow(date: day.0, intake: day.1, goal: dailyGoal)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("History")
            .onAppear {
                updateCache()
            }
            .refreshable {
                updateCache()
            }
            .onChange(of: allDrinks.count) { oldValue, newValue in
                updateCache()
            }
        }
    }
}

struct DayBreakdownRow: View {
    let date: Date
    let intake: Int
    let goal: Int

    private var percentage: Int {
        guard goal > 0 else { return 0 }
        return min(Int((Double(intake) / Double(goal)) * 100), 100)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isToday ? "Today" : date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(isToday ? .primaryBlue : .primary)

                Text(date.formatted(Date.FormatStyle().weekday(.wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(intake) mL")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(percentage)%")
                    .font(.caption)
                    .foregroundColor(percentage >= 100 ? .green : .secondary)
            }

            // Mini progress indicator
            Circle()
                .fill(percentage >= 100 ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(isToday ? Color.primaryBlue.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    HistoryView()
}
