//
//  SettingsView.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Binding var settings: PomodoroSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10){
                Text("Settings")
                    .font(.title2)
                
                // Focus Duration
                StepperRow(
                    label:"Focus",
                    value: $settings.focusDuration,
                    step: 60,
                    range:60...(60*60)
                )
                
                // Short Break
                StepperRow(
                    label: "Short Break",
                    value: $settings.shortBreakDuration,
                    step: 60,
                    range: 60...(60*30)
                )
                
                // Long Break
                StepperRow(
                    label: "Long Break",
                    value: $settings.longBreakDuration,
                    step: 60,
                    range: 60...(60 * 60)
                )
                
                // Sessions before long break
                StepperRow(
                    label: "Sessions",
                    value: $settings.sessionsBeforeLongBreak,
                    step: 1,
                    range: 1...8
                )
                
                // Reset to default settings
                Button("Reset to Defaults") {
                    settings = PomodoroSettings()
                }
                .foregroundStyle(.red)
                .padding(.top, 8)
            }
            .padding()
        }
        
    }
}

/// A reusable stepper row for adjusting a single `PomodoroSettings` value.
///
/// Generic over `V: Strideable` so it handles both `TimeInterval` (durations)
/// and `Int` (session count) with a single component.
///
/// - `TimeInterval` values are displayed in minutes (e.g. "25 min")
/// - `Int` values are displayed as-is (e.g. "4")
///
/// Usage:
/// ```swift
/// StepperRow(
///     label: "Focus",
///     value: $settings.focusDuration,
///     step: 60,
///     range: 60...(60 * 60)
/// ```
private struct StepperRow<V: Strideable>: View where V.Stride: Comparable {
    let label: String
    @Binding var value: V
    let step: V.Stride
    let range: ClosedRange<V>
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Stepper(
                value: $value,
                in: range,
                step: step
            ) {
                Text(displayValue)
                    .font(.body.monospacedDigit())
            }
            .animation(nil, value: value)
        }
    }
    
    private var displayValue: String {
        if let seconds = value as? TimeInterval {
            let minutes = Int(seconds) / 60
            return "\(minutes) min"
        }
        
        return "\(value)"
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State var settings = PomodoroSettings()
        var body: some View {
            SettingsView(settings: $settings)
        }
    }
    return PreviewWrapper()
}
