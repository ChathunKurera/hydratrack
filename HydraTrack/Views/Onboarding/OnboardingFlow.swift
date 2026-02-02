//
//  OnboardingFlow.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentStep = 0
    @State private var age: Int = 25
    @State private var weight: Double = 70
    @State private var gender: Gender = .preferNotToSay
    @State private var activityLevel: ActivityLevel = .lightlyActive

    var body: some View {
        ZStack {
            switch currentStep {
            case 0:
                WelcomeView {
                    withAnimation {
                        currentStep += 1
                    }
                }
            case 1:
                AgeWeightView(age: $age, weight: $weight) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            case 2:
                GenderView(gender: $gender) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            case 3:
                ActivityLevelView(activityLevel: $activityLevel) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            case 4:
                GoalCalculationView(age: age, weight: weight, activityLevel: activityLevel) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            case 5:
                NotificationPermissionView {
                    completeOnboarding()
                }
            default:
                EmptyView()
            }
        }
    }

    private func completeOnboarding() {
        // Create user profile
        let dataService = HydrationDataService(modelContext: modelContext)
        _ = dataService.createUserProfile(
            age: age,
            weightKg: weight,
            gender: gender,
            activityLevel: activityLevel
        )

        // Schedule notifications
        let settings = AppSettings()
        notificationManager.scheduleReminders(
            wakeTime: settings.wakeTime,
            sleepTime: settings.sleepTime,
            frequency: settings.notificationFrequency
        )

        // Mark onboarding as complete
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingFlow()
}
