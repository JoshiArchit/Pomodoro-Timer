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
    
    func sendTimerState(_ state: PomodoroState) {
        guard WCSession.default.isReachable else { return }
        guard let encoded = try? JSONEncoder().encode(TimerStatePayload(from: state)) else { return }
        WCSession.default.sendMessage(
            [ConnectivityKey.timerState: encoded],
            replyHandler: nil
        )
    }
    
    func sendSettings(_ settings: PomodoroSettings) {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        try? WCSession.default.updateApplicationContext(
            [ConnectivityKey.settings: encoded]
        )
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("WCSession activated: \(activationState)")
    }
    
    // iOS only — required delegate methods
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let data = message[ConnectivityKey.timerState] as? Data,
               let payload = try? JSONDecoder().decode(TimerStatePayload.self, from: data) {
                self.receivedTimerState = payload
            }
            
            if let data = message[ConnectivityKey.settings] as? Data,
               let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
                self.receivedSettings = settings
            }
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let data = applicationContext[ConnectivityKey.settings] as? Data,
               let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
                self.receivedSettings = settings
            }
        }
    }
}
