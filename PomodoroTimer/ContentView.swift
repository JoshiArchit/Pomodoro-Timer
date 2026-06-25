//
//  ContentView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/22/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var manager = TimerManager()
    
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
    }
}

#Preview {
    RootView()
}
