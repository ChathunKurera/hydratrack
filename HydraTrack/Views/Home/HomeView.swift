//
//  HomeView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var weatherService: WeatherService
    @Query(sort: \DrinkEntry.timestamp, order: .reverse) private var allDrinks: [DrinkEntry]

    @State private var showingCustomSheet = false
    @State private var cachedProfile: UserProfile?
    @State private var cachedTodayDrinks: [DrinkEntry] = []
    @State private var cachedTotalIntake: Int = 0
    @State private var newAchievements: [Achievement] = []
    @State private var showingAchievementAlert = false
    @State private var goalAdjustmentSuggestion: GoalAdjustmentSuggestion?
    @State private var showingGoalAdjustment = false
    @State private var drinkToEdit: DrinkEntry?

    // Confetti state
    @State private var showConfetti = false
    @State private var previousProgress: Double = 0

    // Undo toast state
    @State private var undoDrink: DrinkEntry?

    // Streak state
    @State private var cachedStreak: Int = 0
    @State private var cachedStreakIsFrozen: Bool = false

    // Weekly summary state
    @State private var cachedWeeklyInsights: WeeklyInsights?
    @State private var cachedWeeklyDailyData: [(date: Date, percentage: Int)] = []

    @AppStorage("lastGoalAdjustmentDate") private var lastGoalAdjustmentDate: Double = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") private var notificationFrequency: Int = 4
    @AppStorage("wakeTimeMinutes") private var wakeTimeMinutes: Int = 420
    @AppStorage("sleepTimeMinutes") private var sleepTimeMinutes: Int = 1380
    @AppStorage("units") private var units: VolumeUnit = .milliliters

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var achievementService: AchievementService {
        AchievementService(modelContext: modelContext)
    }

    private var insightsService: InsightsService {
        InsightsService(modelContext: modelContext)
    }

    private var userProfile: UserProfile? {
        cachedProfile ?? dataService.getUserProfile()
    }

    private var todayDrinks: [DrinkEntry] {
        cachedTodayDrinks
    }

    private var totalIntake: Int {
        cachedTotalIntake
    }

    private var dailyGoal: Int {
        dataService.getEffectiveGoal()
    }

    private var wakeTime: Date {
        Calendar.current.date(bySettingHour: wakeTimeMinutes / 60, minute: wakeTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private var sleepTime: Date {
        Calendar.current.date(bySettingHour: sleepTimeMinutes / 60, minute: sleepTimeMinutes % 60, second: 0, of: Date()) ?? Date()
    }

    private func updateCache() {
        cachedProfile = dataService.getUserProfile()
        cachedTodayDrinks = allDrinks.filter { Calendar.current.isDateInToday($0.timestamp) }
        let oldTotal = cachedTotalIntake
        cachedTotalIntake = cachedTodayDrinks.reduce(0) { $0 + $1.effectiveHydrationMl }

        let goal = dailyGoal
        let newProgress = goal > 0 ? Double(cachedTotalIntake) / Double(goal) : 0

        // Confetti: trigger when crossing 100% upward
        if newProgress >= 1.0 && previousProgress < 1.0 && oldTotal > 0 {
            showConfetti = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        previousProgress = newProgress

        // Streak
        let streakResult = dataService.getCurrentStreakWithFreeze()
        cachedStreak = streakResult.count
        cachedStreakIsFrozen = streakResult.isFrozen

        // Weekly summary
        if let insights = insightsService.getWeeklyInsights() {
            cachedWeeklyInsights = insights
            // Build daily data for the week
            let calendar = Calendar.current
            var dailyData: [(date: Date, percentage: Int)] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: insights.weekStart) else { continue }
                let startOfDay = calendar.startOfDay(for: date)

                if date > Date() {
                    dailyData.append((date: startOfDay, percentage: 0))
                } else {
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                    let descriptor = FetchDescriptor<DrinkEntry>(
                        predicate: #Predicate { drink in
                            drink.timestamp >= startOfDay && drink.timestamp < endOfDay
                        }
                    )
                    let drinks = (try? modelContext.fetch(descriptor)) ?? []
                    let intake = drinks.reduce(0) { $0 + $1.effectiveHydrationMl }
                    let dayGoal = dataService.getEffectiveGoal(for: date)
                    let percentage = dayGoal > 0 ? (intake * 100) / dayGoal : 0
                    dailyData.append((date: startOfDay, percentage: percentage))
                }
            }
            cachedWeeklyDailyData = dailyData
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Progress Ring
                    ProgressRing(current: totalIntake, goal: dailyGoal, unit: units)
                        .padding(.top, 20)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Daily hydration progress")
                        .accessibilityValue("\(units.format(totalIntake)) out of \(units.format(dailyGoal)). \(Int(Double(totalIntake) / Double(dailyGoal) * 100)) percent complete")

                    // Streak Badge
                    if cachedStreak > 0 {
                        StreakBadgeView(streak: cachedStreak, isFrozen: cachedStreakIsFrozen)
                    }

                    // Weather adjustment indicator
                    if weatherService.weatherAdjustmentMl > 0,
                       let temp = weatherService.currentTemperatureCelsius {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.sun.fill")
                                .foregroundColor(.orange)
                            Text("\(Int(temp))°C • +\(units.format(weatherService.weatherAdjustmentMl))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Weekly Summary Card
                    if let insights = cachedWeeklyInsights, !cachedWeeklyDailyData.isEmpty {
                        WeeklySummaryCard(insights: insights, dailyData: cachedWeeklyDailyData)
                    }

                    // Preset Drink Buttons
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Quick Add")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Button(action: {
                                showingCustomSheet = true
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Custom")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.primaryBlue)
                            }
                            .accessibilityLabel("Add custom drink")
                            .accessibilityHint("Opens a sheet to log a custom drink amount and type")
                        }
                        .padding(.horizontal)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 8
                        ) {
                            ForEach(Constants.presetDrinks) { preset in
                                PresetDrinkButton(preset: preset) {
                                    addPresetDrink(preset)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Today's Drinks List
                    if !todayDrinks.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Today's Drinks")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            List {
                                ForEach(todayDrinks) { drink in
                                    DrinkRow(drink: drink, unit: units)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteDrink(drink)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                drinkToEdit = drink
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.primaryBlue)
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(todayDrinks.count) * 80)
                            .scrollDisabled(true)
                        }
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("HydraTrack")
            .onAppear {
                dataService.ensureGoalHistoryExists()
                updateCache()
                checkForGoalAdjustment()
            }
            .refreshable {
                updateCache()
            }
        }
        .sheet(isPresented: $showingCustomSheet) {
            CustomDrinkSheet { volume, type in
                addCustomDrink(volume: volume, type: type)
            }
        }
        .sheet(isPresented: $showingAchievementAlert) {
            if let first = newAchievements.first {
                AchievementUnlockedSheet(achievement: first) {
                    showingAchievementAlert = false
                }
            }
        }
        .sheet(isPresented: $showingGoalAdjustment) {
            if let suggestion = goalAdjustmentSuggestion {
                GoalAdjustmentSheet(
                    suggestion: suggestion,
                    onAccept: { newGoal in
                        dataService.applyGoalAdjustment(newGoal: newGoal)
                        lastGoalAdjustmentDate = Date().timeIntervalSince1970
                        updateCache()
                    },
                    onDismiss: {
                        lastGoalAdjustmentDate = Date().timeIntervalSince1970
                    }
                )
            }
        }
        .sheet(item: $drinkToEdit) { drink in
            EditDrinkSheet(drink: drink) { newVolume, newTime in
                dataService.updateDrink(drink, volumeMl: newVolume, timestamp: newTime)
                updateCache()
            }
        }
        .overlay {
            if showConfetti {
                ConfettiView(isActive: $showConfetti)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .undoToast(drinkToUndo: $undoDrink, unit: units) { drink in
            dataService.deleteDrink(drink)
            Task { @MainActor in
                updateCache()
            }
        }
    }

    private func addPresetDrink(_ preset: PresetDrink) {
        let drink = dataService.addDrink(volumeMl: preset.volumeMl, type: preset.drinkType, name: preset.name)

        // Set up undo (replaces any previous undo opportunity)
        undoDrink = drink

        // Check for new achievements
        checkForAchievements()

        // Update cache immediately
        Task { @MainActor in
            updateCache()
        }

        // Refresh notifications to skip reminders for next 4 hours
        refreshNotifications()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func addCustomDrink(volume: Int, type: DrinkType) {
        let drink = dataService.addDrink(volumeMl: volume, type: type, name: type.rawValue)

        // Set up undo (replaces any previous undo opportunity)
        undoDrink = drink

        // Check for new achievements
        checkForAchievements()

        // Update cache immediately
        Task { @MainActor in
            updateCache()
        }

        // Refresh notifications to skip reminders for next 4 hours
        refreshNotifications()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func checkForAchievements() {
        let achievements = achievementService.checkForNewAchievements()
        if !achievements.isEmpty {
            newAchievements = achievements
            showingAchievementAlert = true

            // Stronger haptic for achievement
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func deleteDrink(_ drink: DrinkEntry) {
        dataService.deleteDrink(drink)

        // Update cache immediately after deletion
        Task { @MainActor in
            updateCache()
        }
    }

    private func checkForGoalAdjustment() {
        // Only check once per day (24 hour cooldown)
        let lastCheck = Date(timeIntervalSince1970: lastGoalAdjustmentDate)
        let hoursSinceLastCheck = Date().timeIntervalSince(lastCheck) / 3600

        guard hoursSinceLastCheck >= 24 else { return }

        // Check if there's a suggestion
        if let suggestion = dataService.checkGoalAdjustment() {
            goalAdjustmentSuggestion = suggestion
            showingGoalAdjustment = true
        }
    }

    private func refreshNotifications() {
        guard notificationsEnabled else { return }
        notificationManager.refreshNotificationsAfterDrink(
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            frequency: notificationFrequency,
            lastDrinkTime: Date()
        )
    }
}

struct DrinkRow: View {
    let drink: DrinkEntry
    var unit: VolumeUnit = .milliliters

    var body: some View {
        HStack {
            Image(systemName: drink.drinkType.icon)
                .foregroundColor(.primaryBlue)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(drink.name)
                    .font(.headline)
                Text(drink.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(unit.format(drink.volumeMl))
                    .font(.subheadline)
                Text(unit.format(drink.effectiveHydrationMl))
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(drink.drinkType.rawValue), \(unit.format(drink.volumeMl))")
        .accessibilityValue("Logged at \(drink.timestamp.formatted(date: .omitted, time: .shortened)), provides \(unit.format(drink.effectiveHydrationMl)) of hydration")
        .accessibilityHint("Swipe left to delete, swipe right to edit")
    }
}

#Preview {
    HomeView()
}
