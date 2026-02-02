//
//  MainTabView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var newAchievementCount = 0

    private var achievementService: AchievementService {
        AchievementService(modelContext: modelContext)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "drop.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(1)

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .badge(newAchievementCount)
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.primaryBlue)
        .onAppear {
            updateNewAchievementCount()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 2 {
                // User viewed achievements tab
                newAchievementCount = 0
            }
        }
    }

    private func updateNewAchievementCount() {
        newAchievementCount = achievementService.getNewAchievementCount()
    }
}

#Preview {
    MainTabView()
}
