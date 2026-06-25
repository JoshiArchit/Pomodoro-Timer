//
//  HistoryView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import SwiftUI
import PomodoroCore

struct HistoryView: View {
    @EnvironmentObject var manager: TimerManager
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            Group {
                if manager.sessionHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !manager.sessionHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            showingClearConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Sessions", role: .destructive) {
                    manager.sessionHistory.removeAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all session history.")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No sessions yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete a Pomodoro session to see your history here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        List(manager.sessionHistory.reversed()) { record in
            SessionRow(record: record)
        }
    }
}

// MARK: - SessionRow

private struct SessionRow: View {
    let record: SessionRecord
    
    var body: some View {
        HStack {
            Circle()
                .fill(phaseColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phaseLabel)
                    .font(.headline)
                Text(record.completedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(record.durationInMinutes) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
    
    private var phaseLabel: String {
        switch record.phase {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }
    
    private var phaseColor: Color {
        switch record.phase {
        case .focus:      return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(TimerManager())
}
