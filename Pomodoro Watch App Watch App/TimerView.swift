//
//  TimerView.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var manager: TimerManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(phaseLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(timeString)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
            
            Text("Session \(manager.state.sessionsCompleted + 1)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                Button(action: { manager.skip() }) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.plain)
                
                Button(action: toggleTimer) {
                    Image(systemName: manager.state.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.plain)
                
                Button(action: { manager.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
            }
            .font(.title3)
        }
    }
    
    // MARK: - Helpers
    
    private func toggleTimer() {
        manager.state.isRunning ? manager.pause() : manager.start()
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
}

#Preview {
    TimerView(manager: TimerManager())
}
