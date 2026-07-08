//
//  ContentView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/22/26.
//

import SwiftUI
import PomodoroCore

struct AppRootView: View {
    @StateObject private var manager = TimerManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .environmentObject(manager)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                manager.resumeIfNeeded()
            }
        }
    }
}

#Preview {
    AppRootView()
}
