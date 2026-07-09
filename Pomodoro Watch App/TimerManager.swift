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

class TimerManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate, UNUserNotificationCenterDelegate {

    @Published var alertDismissTrigger = 0

    @Published var state = PomodoroState() {
        didSet {
            if oldValue.settings != state.settings {
                // Fix up timeRemaining before saving so the snapshot sent to
                // the peer already carries the corrected value.
                if !state.isRunning && state.phaseEndDate == nil {
                    state.timeRemaining = state.totalDuration()
                }
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
    private var extendedSession: WKExtendedRuntimeSession?
    private var lastScheduledNotifID: String?
    private let settingsKey = "pomodoro_settings"
    private let historyKey = "pomodoro_history"

    private let connectivity = ConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var isReceivingRemoteUpdate: Bool = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadSettings()
        loadHistory()
        observeConnectivity()
    }

    deinit {
        displayTimer?.invalidate()
    }

    // MARK: - Timer Control

    func start() {
        state.phaseEndDate = Date().addingTimeInterval(state.timeRemaining)
        state.isRunning = true
        startExtendedSession()
        scheduleCompletionNotification(for: state.phase, id: state.sessionID.uuidString,
                                       at: state.phaseEndDate!)
        syncTimerState()
        startDisplayTimer()
    }

    func pause() {
        if let endDate = state.phaseEndDate {
            state.timeRemaining = max(0, endDate.timeIntervalSinceNow)
        }
        state.phaseEndDate = nil
        state.isRunning = false
        cancelPendingCompletionNotification(id: state.sessionID.uuidString)
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

    /// Call when the watch app returns to the foreground. Restarts the display timer
    /// if a session is still running (extended runtime session may have expired
    /// while the app was backgrounded, stopping the display timer).
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
        WKInterfaceDevice.current().play(.notification)
        // The completion notification was scheduled when the phase started.
        // A natural completion lets it fire (it may already have, if the app
        // was in the background); a skip means it must not fire at all.
        if wasSkipped {
            cancelPendingCompletionNotification(id: completingSessionID.uuidString)
        } else {
            lastScheduledNotifID = completingSessionID.uuidString
        }
        state.advance()
        syncTimerState()
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
        // The extended session is ending (watch backgrounded). Stop the local display
        // timer — we don't need UI updates in the background. Do NOT call pause() here;
        // the anchor in phaseEndDate keeps time correctly and the phone can still detect
        // completion on its end.
        stopDisplayTimer()
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
        guard !isReceivingRemoteUpdate else { return }
        connectivity.sendFullContext(state)
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

    /// Scheduled up front for the phase's end date so it still fires when the
    /// app is suspended in the background at completion time.
    private func scheduleCompletionNotification(for phase: Phase, id: String, at endDate: Date) {
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

        let interval = max(endDate.timeIntervalSinceNow, 0.1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        lastScheduledNotifID = id
    }

    private func cancelPendingCompletionNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        if lastScheduledNotifID == id {
            lastScheduledNotifID = nil
        }
    }

    func acknowledgePhaseCompletion() {
        alertDismissTrigger += 1
        if let id = lastScheduledNotifID {
            // The notification may still be pending if the user acknowledges
            // the in-app alert in the instant before it fires.
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
            connectivity.sendNotificationDismiss(id: id)
            lastScheduledNotifID = nil
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        acknowledgePhaseCompletion()
        completionHandler()
    }

    // MARK: - Connectivity

    private func observeConnectivity() {
        ConnectivityManager.shared.$receivedSettings
            .compactMap { $0 }
            .sink { [weak self] settings in
                guard let self else { return }
                guard settings != state.settings else { return }
                isReceivingRemoteUpdate = true
                // The state didSet resets timeRemaining to the new duration of
                // the *current* phase when idle, and leaves an in-progress
                // countdown untouched — same as a local settings change.
                state.settings = settings
                isReceivingRemoteUpdate = false
            }
            .store(in: &cancellables)

        ConnectivityManager.shared.$receivedTimerState
            .compactMap { $0 }
            .sink { [weak self] payload in
                guard let self else { return }
                isReceivingRemoteUpdate = true
                // If the peer paused or ended the running session early, our
                // locally scheduled completion notification no longer applies.
                if let endDate = state.phaseEndDate, endDate > Date() {
                    cancelPendingCompletionNotification(id: state.sessionID.uuidString)
                }
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
                if payload.isRunning, let endDate = payload.phaseEndDate, endDate > Date() {
                    // Mirror the peer's schedule so this device also notifies
                    // at phase end even if it gets suspended.
                    scheduleCompletionNotification(for: payload.phase,
                                                   id: payload.sessionID.uuidString,
                                                   at: endDate)
                    startDisplayTimer()
                } else if payload.isRunning && payload.phaseEndDate != nil {
                    startDisplayTimer()
                } else {
                    stopDisplayTimer()
                }
                isReceivingRemoteUpdate = false
            }
            .store(in: &cancellables)

        ConnectivityManager.shared.$receivedDismissID
            .compactMap { $0 }
            .sink { [weak self] id in
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
                self?.alertDismissTrigger += 1
            }
            .store(in: &cancellables)
    }

    private func syncTimerState() {
        guard !isReceivingRemoteUpdate else { return }
        connectivity.sendFullContext(state)
    }
}
