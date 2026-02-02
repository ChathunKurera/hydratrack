//
//  AchievementsView.swift
//  HydraTrack
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var unlockedAchievements: [(Achievement, Date)] = []
    @State private var selectedCategory: Achievement.AchievementCategory? = nil

    private var achievementService: AchievementService {
        AchievementService(modelContext: modelContext)
    }

    private var unlockedIds: Set<String> {
        Set(unlockedAchievements.map { $0.0.id })
    }

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return Achievement.all.filter { $0.category == category }
        }
        return Achievement.all
    }

    private var progress: (unlocked: Int, total: Int) {
        (unlockedAchievements.count, Achievement.all.count)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Card
                    progressCard

                    // Category Filter
                    categoryPicker

                    // Achievements Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: unlockedIds.contains(achievement.id),
                                unlockedDate: unlockedAchievements.first(where: { $0.0.id == achievement.id })?.1
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .onAppear {
                loadAchievements()
                achievementService.markAllAsSeen()
            }
        }
    }

    private var progressCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(progress.unlocked) / \(progress.total)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Achievements Unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int((Double(progress.unlocked) / Double(progress.total)) * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBlue)

                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach([
                    Achievement.AchievementCategory.streak,
                    .volume,
                    .consistency,
                    .milestone,
                    .variety,
                    .timing,
                    .challenge
                ], id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func loadAchievements() {
        unlockedAchievements = achievementService.getUnlockedAchievements()
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryBlue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedDate: Date?

    private var primaryColor: Color {
        if let customColors = achievement.customColors {
            return customColors.primary
        }
        return categoryColor
    }

    private var secondaryColor: Color {
        if let customColors = achievement.customColors {
            return customColors.secondary
        }
        return categoryColor
    }

    private var hasCustomColors: Bool {
        achievement.customColors != nil
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if hasCustomColors && isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                } else {
                    Circle()
                        .fill(isUnlocked ? categoryColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                }

                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundColor(isUnlocked ? (hasCustomColors ? secondaryColor : categoryColor) : .gray.opacity(0.4))
            }

            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .gray)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let date = unlockedDate {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .frame(height: 200)
        .background(isUnlocked ? Color.gray.opacity(0.05) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? (hasCustomColors ? primaryColor : categoryColor.opacity(0.3)) : Color.gray.opacity(0.2), lineWidth: hasCustomColors && isUnlocked ? 3 : 2)
        )
        .cornerRadius(16)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .streak: return .orange
        case .volume: return .blue
        case .consistency: return .green
        case .milestone: return .purple
        case .variety: return .pink
        case .timing: return .cyan
        case .challenge: return .red
        }
    }
}

#Preview {
    AchievementsView()
}
