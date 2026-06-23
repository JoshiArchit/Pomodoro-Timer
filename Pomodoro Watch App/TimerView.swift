import SwiftUI

struct TimerView: View {
    @ObservedObject var manager: TimerManager
    @State private var showingAlert = false
    @State private var completedPhase: Phase = .focus
    
    var body: some View {
        VStack(spacing: 8) {
            Text(phaseLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(timeString)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
            
            Text(sessionLabel)
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
}

#Preview {
    let manager = TimerManager()
    return TimerView(manager: manager)
}
