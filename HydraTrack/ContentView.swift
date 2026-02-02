//
//  ContentView.swift
//  HydraTrack
//
//  Created by Chathun Kurera on 1/25/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView()
}
