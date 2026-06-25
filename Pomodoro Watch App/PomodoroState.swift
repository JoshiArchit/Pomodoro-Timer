//
//  PomodoroState.swift
//  Pomodoro Watch App Watch App
//
//  Created by Archit Joshi on 6/22/26.
//

import Foundation

enum Phase {
    case focus
    case shortBreak
    case longBreak
}

struct PomodoroSettings {
    var focusDuration: TimeInterval = 25 * 60
    var shortBreakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval = 15 * 60
    var sessionsBeforeLongBreak: Int = 4
}

struct PomodoroState {
    var phase: Phase = .focus
    var timeRemaining: TimeInterval = 25 * 60
    var sessionsCompleted: Int = 0
    var isRunning: Bool = false
    var settings: PomodoroSettings = PomodoroSettings()

    func totalDuration() -> TimeInterval {
        switch phase {
        case .focus:      return settings.focusDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak:  return settings.longBreakDuration
        }
    }

    mutating func advance() {
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
