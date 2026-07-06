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
    @State private var isShowingSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if isShowingSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                isShowingSplash = false
                            }
                        }
                    }
            } else {
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
                .transition(.opacity)
            }
        }
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
