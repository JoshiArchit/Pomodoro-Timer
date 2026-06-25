//
//  TimerManager.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation
import PomodoroCore
import UserNotifications
import Combine

class TimerManager: NSObject, ObservableObject {
    @Published var sessionHistory: [SessionRecord] = []
    @Published var state = PomodoroState()
    
    private var timer: Timer?
    
    // MARK: - Timer Control
    
    func start() {
        state.isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        state.isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        pause()
        state.timeRemaining = state.totalDuration()
    }
    
    func skip() {
        pause()
        state.advance()
    }
    
    // MARK: - Tick
    
    private func tick() {
        if state.timeRemaining > 0 {
            state.timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }
    
    private func sessionCompleted() {
        let record = SessionRecord(
            phase: state.phase,
            duration: state.totalDuration()
        )
        sessionHistory.append(record)
        pause()
        scheduleNotification(for: state.phase)
        state.advance()
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for phase: Phase) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch phase {
        case .focus:
            content.title = "Focus Complete 🍅"
            content.body = "Time for a break!"
        case .shortBreak:
            content.title = "Break Over"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Ready for another round?"
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
