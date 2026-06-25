import SwiftUI

struct TimerView: View {
    @ObservedObject var manager: TimerManager
    @State private var showingAlert = false
    @State private var completedPhase: Phase = .focus
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ProgressRing(progress: progress, color: phaseColor)
                    .frame(width: geometry.size.width - 5, height: geometry.size.width - 5)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                VStack(spacing: 8) {
                    Text(phaseLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("phaseLabel")
                    
                    Text(timeString)
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .accessibilityIdentifier("timerLabel")
                    
                    Text(sessionLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("sessionLabel")
                    
                    HStack(spacing: 16) {
                        Button(action: { manager.skip() }) {
                            Image(systemName: "forward.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("skipButton")
                        
                        Button(action: toggleTimer) {
                            Image(systemName: manager.state.isRunning ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("playPauseButton")
                        
                        Button(action: { manager.reset() }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("resetButton")
                    }
                    .font(.title3)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
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
    
    // MARK: - Helpers
    
    private func toggleTimer() {
        manager.state.isRunning ? manager.pause() : manager.start()
    }
    
    private var phaseLabel: String {
        switch manager.state.phase {
        case .focus:                  return "Focus"
        case .shortBreak:             return "Short Break"
        case .longBreak:              return "Long Break"
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
    
    private var progress: Double {
        let total = manager.state.totalDuration()
        let remaining = manager.state.timeRemaining
        return remaining / total
    }

    private var phaseColor: Color {
        switch manager.state.phase {
        case .focus:      return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }
}

#Preview {
    let manager = TimerManager()
    return TimerView(manager: manager)
}
