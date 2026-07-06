// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum Phase: Codable {
    case focus
    case shortBreak
    case longBreak
}

public struct PomodoroSettings: Codable, Equatable {
    public var focusDuration: TimeInterval = 25 * 60
    public var shortBreakDuration: TimeInterval = 5 * 60
    public var longBreakDuration: TimeInterval = 15 * 60
    public var sessionsBeforeLongBreak: Int = 4
    
    public init() {}
}

public struct PomodoroState {
    public var phase: Phase = .focus
    public var timeRemaining: TimeInterval = 25 * 60
    public var sessionsCompleted: Int = 0
    public var isRunning: Bool = false
    public var settings: PomodoroSettings = PomodoroSettings()
    /// Set to `Date() + timeRemaining` when the timer starts; nil when paused.
    /// Both devices compute the countdown locally from this anchor instead of
    /// receiving per-second ticks, so backgrounding one device doesn't freeze the other.
    public var phaseEndDate: Date? = nil
    /// Changes on every phase advance so either device can detect double-completion.
    public var sessionID: UUID = UUID()

    public init() {}

    public func totalDuration() -> TimeInterval {
        switch phase {
        case .focus:      return settings.focusDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak:  return settings.longBreakDuration
        }
    }

    public mutating func advance() {
        sessionID = UUID()
        switch phase {
        case .focus:
            sessionsCompleted += 1
            if sessionsCompleted % settings.sessionsBeforeLongBreak == 0 {
                phase = .longBreak
                timeRemaining = settings.longBreakDuration
            } else {
                phase = .shortBreak
                timeRemaining = settings.shortBreakDuration
            }
        case .shortBreak, .longBreak:
            phase = .focus
            timeRemaining = settings.focusDuration
        }
    }
}
