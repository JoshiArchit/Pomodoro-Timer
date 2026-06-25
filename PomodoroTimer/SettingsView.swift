//
//  SettingsView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import SwiftUI
import PomodoroCore

struct SettingsView: View {
    @StateObject private var manager = TimerManager()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Focus") {
                    DurationPicker(
                        label: "Duration",
                        value: $manager.state.settings.focusDuration,
                        range: 1...60
                    )
                }
                
                Section("Breaks") {
                    DurationPicker(
                        label: "Short Break",
                        value: $manager.state.settings.shortBreakDuration,
                        range: 1...30
                    )
                    
                    DurationPicker(
                        label: "Long Break",
                        value: $manager.state.settings.longBreakDuration,
                        range: 1...60
                    )
                }
                
                Section("Sessions") {
                    Stepper(
                        "Sessions before long break: \(manager.state.settings.sessionsBeforeLongBreak)",
                        value: $manager.state.settings.sessionsBeforeLongBreak,
                        in: 1...8
                    )
                }
                
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        manager.state.settings = PomodoroSettings()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - DurationPicker

private struct DurationPicker: View {
    let label: String
    @Binding var value: TimeInterval
    let range: ClosedRange<Int>
    
    // Convert TimeInterval to minutes for the picker
    private var minutes: Binding<Int> {
        Binding(
            get: { Int(value / 60) },
            set: { value = TimeInterval($0 * 60) }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            
            Picker(label, selection: minutes) {
                ForEach(range, id: \.self) { minute in
                    Text("\(minute) min").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
        }
    }
}

#Preview {
    SettingsView()
}
