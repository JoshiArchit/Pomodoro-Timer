//
//  TimerManager.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation
import Combine
import PomodoroCore
import UserNotifications

class TimerManager: NSObject, ObservableObject {
    
    @Published var state = PomodoroState() {
        didSet {
            if oldValue.settings != state.settings {
                saveSettings()
            }
        }
    }
    @Published var sessionHistory: [SessionRecord] = [] {
        didSet { saveHistory() }
    }
    
    private var timer: Timer?
    private let settingsKey = "pomodoro_settings"
    private let historyKey = "pomodoro_history"
    
    private let connectivity = ConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var isReceivingRemoteUpdates = false
    
    override init() {
        super.init()
        loadSettings()
        loadHistory()
        observeConnectivity()
    }
    
    // MARK: - Timer Control
    
    func start() {
        state.isRunning = true
        syncTimerState()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        state.isRunning = false
        timer?.invalidate()
        timer = nil
        syncTimerState()
    }
    
    func reset() {
        pause()
        state.timeRemaining = state.totalDuration()
        syncTimerState()
    }
    
    func skip() {
        pause()
        sessionCompleted(wasSkipped:true)
    }
    
    // MARK: - Tick
    
    private func tick() {
        if state.timeRemaining > 0 {
            state.timeRemaining -= 1
            syncTimerState()
        } else {
            sessionCompleted()
        }
    }
    
    private func sessionCompleted(wasSkipped:Bool = false) {
        let record = SessionRecord(
            phase: state.phase,
            duration: state.totalDuration(),
            wasSkipped: wasSkipped
        )
        sessionHistory.append(record)
        pause()
        scheduleNotification(for: state.phase)
        state.advance()
        syncTimerState()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        guard let encoded = try? JSONEncoder().encode(state.settings) else { return }
        UserDefaults.standard.set(encoded, forKey: settingsKey)
        guard !isReceivingRemoteUpdates else { return }
        connectivity.sendSettings(state.settings)
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
    
    // MARK: Connectivity
    private func observeConnectivity() {
        ConnectivityManager.shared.$receivedSettings
            .compactMap { $0 }
            .sink { [weak self] settings in
                guard let self else { return }
                isReceivingRemoteUpdates = true
                state.settings = settings
                state.timeRemaining = settings.focusDuration
                isReceivingRemoteUpdates = false
            }
            .store(in: &cancellables)
        
        ConnectivityManager.shared.$receivedTimerState
            .compactMap { $0 }
            .sink { [weak self] payload in
                guard let self else { return }
                isReceivingRemoteUpdates = true
                state.timeRemaining = payload.timeRemaining
                state.phase = payload.phase
                state.isRunning = payload.isRunning
                state.sessionsCompleted = payload.sessionsCompleted
                if !payload.isRunning {
                    timer?.invalidate()
                    timer = nil
                }
                isReceivingRemoteUpdates = false
            }
            .store(in: &cancellables)
    }
    
    private func syncTimerState() {
        guard !isReceivingRemoteUpdates else { return }
        connectivity.sendTimerState(state)
    }
    
    // MARK: - Preview

    static var preview: TimerManager {
        let manager = TimerManager()
        manager.sessionHistory = [
            SessionRecord(phase: .focus, duration: 1500),
            SessionRecord(phase: .shortBreak, duration: 300),
            SessionRecord(phase: .focus, duration: 1500, wasSkipped: true),
            SessionRecord(phase: .focus, duration: 1500),
            SessionRecord(phase: .longBreak, duration: 900),
        ]
        return manager
    }
}
