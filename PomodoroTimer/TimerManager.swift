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

    /// Local display-only timer. Recomputes `state.timeRemaining` from `phaseEndDate`
    /// so the UI keeps ticking regardless of what the peer device is doing.
    private var displayTimer: Timer?
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
        state.phaseEndDate = Date().addingTimeInterval(state.timeRemaining)
        state.isRunning = true
        syncTimerState()
        startDisplayTimer()
    }

    func pause() {
        if let endDate = state.phaseEndDate {
            state.timeRemaining = max(0, endDate.timeIntervalSinceNow)
        }
        state.phaseEndDate = nil
        state.isRunning = false
        stopDisplayTimer()
        syncTimerState()
    }

    func reset() {
        pause()
        state.timeRemaining = state.totalDuration()
        syncTimerState()
    }

    func skip() {
        sessionCompleted(wasSkipped: true, completingSessionID: state.sessionID)
    }

    /// Call when the app returns to the foreground. Restarts the display timer
    /// if a session is still in progress (iOS may have suspended the app, pausing the timer).
    func resumeIfNeeded() {
        guard state.isRunning, state.phaseEndDate != nil, displayTimer == nil else { return }
        startDisplayTimer()
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.displayTick()
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func displayTick() {
        guard let endDate = state.phaseEndDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            sessionCompleted(completingSessionID: state.sessionID)
        } else {
            state.timeRemaining = remaining
        }
    }

    // MARK: - Session Completion

    /// `completingSessionID` is captured at the moment of detection so that a
    /// concurrent remote advance (which changes `state.sessionID`) causes the
    /// guard to fail, preventing double-completion.
    private func sessionCompleted(wasSkipped: Bool = false, completingSessionID: UUID) {
        guard state.sessionID == completingSessionID else { return }

        let record = SessionRecord(
            phase: state.phase,
            duration: state.totalDuration(),
            wasSkipped: wasSkipped
        )
        sessionHistory.append(record)

        state.phaseEndDate = nil
        state.isRunning = false
        stopDisplayTimer()
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

    // MARK: - Connectivity

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
                state.phase = payload.phase
                state.sessionsCompleted = payload.sessionsCompleted
                state.isRunning = payload.isRunning
                state.phaseEndDate = payload.phaseEndDate
                state.sessionID = payload.sessionID
                if let endDate = payload.phaseEndDate {
                    state.timeRemaining = max(0, endDate.timeIntervalSinceNow)
                } else {
                    state.timeRemaining = payload.timeRemaining
                }
                if payload.isRunning && payload.phaseEndDate != nil {
                    startDisplayTimer()
                } else {
                    stopDisplayTimer()
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
