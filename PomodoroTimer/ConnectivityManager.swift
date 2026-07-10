//
//  ConnectivityManager.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation
import WatchConnectivity
import PomodoroCore
import Combine

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    
    static let shared = ConnectivityManager()
    
    @Published var receivedSettings: PomodoroSettings?
    @Published var receivedTimerState: TimerStatePayload?
    @Published var receivedDismissID: String?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    // MARK: - Send
    
    /// Sends the timer state and settings together as one fresh snapshot.
    /// Merging single keys into the previously sent context left the other key
    /// stale (e.g. a settings send re-broadcasting a long-finished session),
    /// so the full context is always rebuilt from the current state.
    func sendFullContext(_ state: PomodoroState) {
        guard WCSession.default.activationState == .activated else {
            NSLog("[Connectivity] send skipped — session not activated (state: %d)",
                  WCSession.default.activationState.rawValue)
            return
        }
        guard let timerData = try? JSONEncoder().encode(TimerStatePayload(from: state)),
              let settingsData = try? JSONEncoder().encode(state.settings) else { return }
        let context: [String: Any] = [
            ConnectivityKey.timerState: timerData,
            ConnectivityKey.settings: settingsData,
        ]
        do {
            try WCSession.default.updateApplicationContext(context)
            NSLog("[Connectivity] sent context (running: %d)", state.isRunning ? 1 : 0)
        } catch {
            NSLog("[Connectivity] updateApplicationContext failed: %@", error.localizedDescription)
        }
    }

    func sendNotificationDismiss(id: String) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo([ConnectivityKey.dismissNotification: id])
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("WCSession activated: \(activationState)")
        guard activationState == .activated else { return }
        // Contexts delivered while this app wasn't running don't trigger
        // didReceiveApplicationContext — replay the last one so launching the
        // app picks up whatever the peer did in the meantime.
        processApplicationContext(session.receivedApplicationContext)
    }
    
    // iOS only — required delegate methods
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            if let id = userInfo[ConnectivityKey.dismissNotification] as? String {
                self.receivedDismissID = id
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        processApplicationContext(applicationContext)
    }

    private func processApplicationContext(_ applicationContext: [String: Any]) {
        NSLog("[Connectivity] received context keys: %@", applicationContext.keys.joined(separator: ","))
        DispatchQueue.main.async {
            if let data = applicationContext[ConnectivityKey.timerState] as? Data,
               let payload = try? JSONDecoder().decode(TimerStatePayload.self, from: data) {
                self.receivedTimerState = payload
            }
            if let data = applicationContext[ConnectivityKey.settings] as? Data,
               let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
                self.receivedSettings = settings
            }
        }
    }
}
