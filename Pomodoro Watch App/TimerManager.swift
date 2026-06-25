//
//  TimeManager.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import Foundation
import WatchKit
import Combine
import UserNotifications
import PomodoroCore

class TimerManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    
    @Published var state = PomodoroState() {
        didSet { saveSettings() }
    }
    @Published var sessionHistory: [SessionRecord] = [] {
        didSet { saveHistory() }
    }
    
    private var timer: Timer?
    private var extendedSession: WKExtendedRuntimeSession?
    private let settingsKey = "pomodoro_settings"
    private let historyKey = "pomodoro_history"
    
    override init() {
        super.init()
        loadSettings()
        loadHistory()
    }
    
    // MARK: - Timer Control
    
    func start() {
        state.isRunning = true
        startExtendedSession()
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
        WKInterfaceDevice.current().play(.notification)
        scheduleNotification(for: state.phase)
        state.advance()
    }
    
    // MARK: - Extended Runtime Session
    
    private func startExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start()
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended session started")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        pause()
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        print("Extended session invalidated: \(reason)")
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        guard let encoded = try? JSONEncoder().encode(state.settings) else { return }
        UserDefaults.standard.set(encoded, forKey: settingsKey)
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data)
        else { return }
        state.settings = settings
        state.timeRemaining = settings.focusDuration
    }
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(sessionHistory) else { return }
        UserDefaults.standard.set(encoded, forKey: historyKey)
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return }
        sessionHistory = history
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
