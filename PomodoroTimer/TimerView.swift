//
//  TimerView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import SwiftUI
import PomodoroCore

struct TimerView: View {
    @StateObject private var manager = TimerManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                // Progress Ring
                ZStack {
                    ProgressRing(progress: progress, color: phaseColor)
                        .frame(width: 280, height: 280)
                    
                    VStack(spacing: 8) {
                        Text(phaseLabel)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(timeString)
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                        
                        Text(sessionLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Controls
                HStack(spacing: 48) {
                    Button(action: { manager.skip() }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                    
                    Button(action: toggleTimer) {
                        Image(systemName: manager.state.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                    }
                    
                    Button(action: { manager.reset() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                    }
                }
                .foregroundStyle(phaseColor)
            }
            .padding()
            .navigationTitle("Pomodoro")
            .alert(phaseCompleteTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(phaseCompleteMessage)
            }
            .onChange(of: manager.state.phase) { oldPhase, newPhase in
                completedPhase = oldPhase
                showingAlert = true
            }
        }
    }
    
    // MARK: - State
    
    @State private var showingAlert = false
    @State private var completedPhase: Phase = .focus
    
    // MARK: - Helpers
    
    private func toggleTimer() {
        manager.state.isRunning ? manager.pause() : manager.start()
    }
    
    private var progress: Double {
        manager.state.timeRemaining / manager.state.totalDuration()
    }
    
    private var phaseColor: Color {
        switch manager.state.phase {
        case .focus:      return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
    
    private var phaseLabel: String {
        switch manager.state.phase {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }
    
    private var timeString: String {
        let minutes = Int(manager.state.timeRemaining) / 60
        let seconds = Int(manager.state.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var sessionLabel: String {
        switch manager.state.phase {
        case .focus:
            return "Session \(manager.state.sessionsCompleted + 1)"
        case .shortBreak, .longBreak:
            return "Session \(manager.state.sessionsCompleted) complete"
        }
    }
    
    private var phaseCompleteTitle: String {
        switch completedPhase {
        case .focus:                  return "Break Time!"
        case .shortBreak, .longBreak: return "Focus Time!"
        }
    }
    
    private var phaseCompleteMessage: String {
        switch completedPhase {
        case .focus:      return "Time for a break 🎉"
        case .shortBreak: return "Ready to focus? 🍅"
        case .longBreak:  return "Long break over — let's go!"
        }
    }
}

#Preview {
    TimerView()
}

#Preview {
    TimerView()
}
