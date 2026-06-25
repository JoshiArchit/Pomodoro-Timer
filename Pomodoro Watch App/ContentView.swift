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
    
    var body: some View {
        TabView {
            TimerView(manager: manager)
            SettingsView(settings: $manager.state.settings)
        }
        .tabViewStyle(.verticalPage)
    }
}
#Preview {
    ContentView()
}
