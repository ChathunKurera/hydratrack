//
//  SettingsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weatherService: WeatherService

    @AppStorage("units") private var units: VolumeUnit = .milliliters
    @AppStorage("wakeTimeMinutes") private var wakeTimeMinutes: Int = 420
    @AppStorage("sleepTimeMinutes") private var sleepTimeMinutes: Int = 1380
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationFrequency") private var notificationFrequency: Int = 4

    @State private var showingGoalBreakdown = false
    @State private var customGoal: String = ""
    @State private var useCustomGoal: Bool = false
    @State private var cachedProfile: UserProfile?
    @State private var todayGoalOverride: String = ""
    @State private var hasTodayOverride: Bool = false
    @State private var showTodayOverride: Bool = false

    private var dataService: HydrationDataService {
        HydrationDataService(modelContext: modelContext)
    }

    private var userProfile: UserProfile? {
        cachedProfile ?? dataService.getUserProfile()
    }

    private func updateProfileCache() {
        cachedProfile = dataService.getUserProfile()
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Hydration Goal (Most frequently adjusted)
                Section {
                    if let profile = userProfile {
                        // Current Goal - Prominent display
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Goal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(units.format(profile.dailyGoalMl))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primaryBlue)
                            }

                            Spacer()

                            Button {
                                showingGoalBreakdown = true
                            } label: {
                                Text("Breakdown")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.primaryBlue.opacity(0.1))
                                    .foregroundColor(.primaryBlue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)

                        // Custom Goal Toggle
                        Toggle("Custom Goal", isOn: $useCustomGoal)
                            .onChange(of: useCustomGoal) { _, newValue in
                                if !newValue {
                                    dataService.setCustomGoal(nil, for: profile)
                                    updateProfileCache()
                                }
                            }

                        if useCustomGoal {
                            HStack {
                                TextField("Goal (\(units.abbreviation))", text: $customGoal)
                                    .keyboardType(.decimalPad)

                                Button("Set") {
                                    if let value = Double(customGoal) {
                                        let goalMl = units.convertToMl(from: value)
                                        if goalMl >= 1500 && goalMl <= 3200 {
                                            dataService.setCustomGoal(goalMl, for: profile)
                                            updateProfileCache()
                                        }
                                    }
                                }
                                .disabled(customGoal.isEmpty)
                            }
                        }

                        // Today's Override - Collapsible
                        DisclosureGroup(
                            isExpanded: $showTodayOverride,
                            content: {
                                if hasTodayOverride, let override = dataService.getTodayGoalOverride() {
                                    HStack {
                                        Text("Today's Goal")
                                        Spacer()
                                        Text(units.format(override))
                                            .foregroundColor(.orange)
                                            .fontWeight(.semibold)
                                    }

                                    Button(role: .destructive) {
                                        dataService.clearTodayGoalOverride()
                                        hasTodayOverride = false
                                        todayGoalOverride = ""
                                    } label: {
                                        Text("Reset to Regular Goal")
                                            .frame(maxWidth: .infinity)
                                    }
                                } else {
                                    HStack {
                                        TextField("Override (\(units.abbreviation))", text: $todayGoalOverride)
                                            .keyboardType(.decimalPad)

                                        Button("Set") {
                                            if let value = Double(todayGoalOverride) {
                                                let goalMl = units.convertToMl(from: value)
                                                if goalMl >= 1000 && goalMl <= 5000 {
                                                    dataService.setTodayGoalOverride(goalMl: goalMl)
                                                    hasTodayOverride = true
                                                }
                                            }
                                        }
                                        .disabled(todayGoalOverride.isEmpty)
                                    }

                                    Text("Resets tomorrow")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            },
                            label: {
                                HStack {
                                    Text("Today Only")
                                    if hasTodayOverride {
                                        Spacer()
                                        Text("Active")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        )
                    }
                } header: {
                    Label("Hydration Goal", systemImage: "target")
                }

                // MARK: - Quick Settings
                Section {
                    Picker("Volume Unit", selection: $units) {
                        ForEach(VolumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Units", systemImage: "ruler")
                }

                // MARK: - Notifications (NavigationLink to sub-page)
                Section {
                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        HStack {
                            Text("Reminders")
                            Spacer()
                            Text(notificationsEnabled ? "\(notificationFrequency)/day" : "Off")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Notifications", systemImage: "bell")
                }

                // MARK: - Weather Adjustment
                Section {
                    Toggle("Weather-Based", isOn: Binding(
                        get: { weatherService.isEnabled },
                        set: { newValue in
                            if newValue {
                                weatherService.requestLocationPermission()
                            }
                            weatherService.setEnabled(newValue)
                        }
                    ))

                    if weatherService.isEnabled {
                        if let temp = weatherService.currentTemperatureCelsius {
                            HStack {
                                Text("\(Int(temp))°C")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("+\(units.format(weatherService.weatherAdjustmentMl))")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        } else if weatherService.locationStatus == .denied || weatherService.locationStatus == .restricted {
                            Text("Location access denied")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            HStack {
                                Text("Fetching...")
                                    .foregroundColor(.secondary)
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                } header: {
                    Label("Weather", systemImage: "thermometer.sun")
                } footer: {
                    Text("Increase goal on hot days (up to +\(units.format(250)))")
                }

                // MARK: - Sleep Schedule (NavigationLink to sub-page)
                Section {
                    NavigationLink {
                        SleepScheduleSettingsView()
                    } label: {
                        HStack {
                            Text("Schedule")
                            Spacer()
                            Text(sleepScheduleSummary)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Sleep Schedule", systemImage: "moon.zzz")
                }

                // MARK: - Profile (NavigationLink to sub-page)
                Section {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        if let profile = userProfile {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.gender.rawValue)
                                        .font(.subheadline)
                                    Text("\(profile.age)y • \(Int(profile.weightKg))kg • \(profile.activityLevel.shortName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        } else {
                            Text("Set up profile")
                        }
                    }
                } header: {
                    Label("Profile", systemImage: "person.crop.circle")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingGoalBreakdown) {
            if let profile = userProfile {
                NavigationView {
                    ScrollView {
                        GoalBreakdownView(
                            breakdown: GoalCalculator.getBreakdown(
                                age: profile.age,
                                weightKg: profile.weightKg,
                                activityLevel: profile.activityLevel
                            )
                        )
                        .padding()
                    }
                    .navigationTitle("Goal Breakdown")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingGoalBreakdown = false
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            updateProfileCache()
            if let profile = userProfile, profile.customGoalMl != nil {
                useCustomGoal = true
                customGoal = "\(profile.customGoalMl!)"
            }
            if let override = dataService.getTodayGoalOverride() {
                hasTodayOverride = true
                todayGoalOverride = "\(override)"
            }
        }
    }

    private var sleepScheduleSummary: String {
        let wakeHour = wakeTimeMinutes / 60
        let wakeMin = wakeTimeMinutes % 60
        let sleepHour = sleepTimeMinutes / 60
        let sleepMin = sleepTimeMinutes % 60
        return String(format: "%d:%02d - %d:%02d", wakeHour, wakeMin, sleepHour, sleepMin)
    }
}

#Preview {
    SettingsView()
}
