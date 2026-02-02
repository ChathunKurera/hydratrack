//
//  HomeView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrinkEntry.timestamp, order: .reverse) private var allDrinks: [DrinkEntry]

    @State private var showingCustomSheet = false
    @State private var cachedProfile: UserProfile?
    @State private var cachedTodayDrinks: [DrinkEntry] = []
    @State private var cachedTotalIntake: Int = 0
    @State private var newAchievements: [Achievement] = []
    @State private var showingAchievementAlert = false
    @State private var goalAdjustmentSuggestion: GoalAdjustmentSuggestion?
    @State private var showingGoalAdjustment = false

    @AppStorage("lastGoalAdjustmentDate") private var lastGoalAdjustmentDate: Double = 0

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var achievementService: AchievementService {
        AchievementService(modelContext: modelContext)
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

    private func updateCache() {
        cachedProfile = dataService.getUserProfile()
        cachedTodayDrinks = allDrinks.filter { Calendar.current.isDateInToday($0.timestamp) }
        cachedTotalIntake = cachedTodayDrinks.reduce(0) { $0 + $1.effectiveHydrationMl }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Progress Ring
                    ProgressRing(current: totalIntake, goal: dailyGoal)
                        .padding(.top, 20)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Daily hydration progress")
                        .accessibilityValue("\(totalIntake) milliliters out of \(dailyGoal) milliliters. \(Int(Double(totalIntake) / Double(dailyGoal) * 100)) percent complete")

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
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Today's Drinks")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(todayDrinks) { drink in
                                DrinkRow(drink: drink) {
                                    deleteDrink(drink)
                                }
                                .padding(.horizontal)
                            }
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
        .alert("Achievement Unlocked!", isPresented: $showingAchievementAlert) {
            Button("OK") {
                showingAchievementAlert = false
            }
        } message: {
            if let first = newAchievements.first {
                Text("\(first.icon) \(first.title)\n\(first.description)")
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
    }

    private func addPresetDrink(_ preset: PresetDrink) {
        dataService.addDrink(volumeMl: preset.volumeMl, type: preset.drinkType, name: preset.name)

        // Check for new achievements
        checkForAchievements()

        // Update cache immediately
        Task { @MainActor in
            updateCache()
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func addCustomDrink(volume: Int, type: DrinkType) {
        dataService.addDrink(volumeMl: volume, type: type, name: type.rawValue)

        // Check for new achievements
        checkForAchievements()

        // Update cache immediately
        Task { @MainActor in
            updateCache()
        }

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
}

struct DrinkRow: View {
    let drink: DrinkEntry
    let onDelete: () -> Void

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
                Text("\(drink.volumeMl) mL")
                    .font(.subheadline)
                Text("\(drink.effectiveHydrationMl) mL")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete drink entry")
            .accessibilityHint("Removes this \(drink.volumeMl) milliliter \(drink.drinkType.rawValue) from your log")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(drink.drinkType.rawValue), \(drink.volumeMl) milliliters")
        .accessibilityValue("Logged at \(drink.timestamp.formatted(date: .omitted, time: .shortened)), provides \(drink.effectiveHydrationMl) milliliters of hydration")
    }
}

#Preview {
    HomeView()
}
