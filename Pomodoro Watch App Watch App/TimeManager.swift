//
//  TimeManager.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import Foundation
import WatchKit
import Combine

class TimerManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    
    @Published var state = PomodoroState() // Expose state to Views so they can subscribe to it
    
    private var timer: Timer?
    private var extendedSession: WKExtendedRuntimeSession?
    
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
        pause()
        WKInterfaceDevice.current().play(.notification)
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
        // Session is about to expire — pause gracefully
        pause()
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        print("Extended session invalidated: \(reason)")
    }
}

