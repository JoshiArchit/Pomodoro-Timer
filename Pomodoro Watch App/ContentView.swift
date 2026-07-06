//
//  ContentView.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import SwiftUI
import PomodoroCore

struct ContentView: View {
    @StateObject private var manager = TimerManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TimerView(manager: manager)
            SettingsView(settings: $manager.state.settings)
        }
        .tabViewStyle(.verticalPage)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                manager.resumeIfNeeded()
            }
        }
    }
}
#Preview {
    ContentView()
}
