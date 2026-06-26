//
//  File.swift
//  PomodoroCore
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation

/// Keys used for WatchConnectivity message passing
public enum ConnectivityKey {
    public static let settings = "settings"
    public static let timerState = "timerState"
    public static let sessionHistory = "sessionHistory"
}

/// Codable payload for syncing timer state
public struct TimerStatePayload: Codable {
    public let isRunning: Bool
    public let timeRemaining: TimeInterval
    public let phase: Phase
    public let sessionsCompleted: Int
    
    public init(from state: PomodoroState) {
        self.isRunning = state.isRunning
        self.timeRemaining = state.timeRemaining
        self.phase = state.phase
        self.sessionsCompleted = state.sessionsCompleted
    }
}
