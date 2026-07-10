//
//  PomodoroWatchAppTests.swift
//  PomodoroWatchAppTests
//
//  Created by Archit Joshi on 6/23/26.
//

import Testing
internal import PomodoroCore
@testable import PomodoroWatchApp

struct PomodoroStateTests {
    
    // MARK: - Phase Advancement
    
    @Test func advance_fromFocus_goesToShortBreak() {
        var state = PomodoroState()
        state.advance()
        #expect(state.phase == .shortBreak)
    }
    
    @Test func advance_fromShortBreak_goesToFocus() {
        var state = PomodoroState()
        state.phase = .shortBreak
        state.advance()
        #expect(state.phase == .focus)
    }
    
    @Test func advance_fromLongBreak_goesToFocus() {
        var state = PomodoroState()
        state.phase = .longBreak
        state.advance()
        #expect(state.phase == .focus)
    }
    
    @Test func advance_afterFourSessions_goesToLongBreak() {
        var state = PomodoroState()
        state.sessionsCompleted = 3
        state.advance()
        #expect(state.phase == .longBreak)
    }
    
    // MARK: - Session Counting
    
    @Test func advance_fromFocus_incrementsSessionCount() {
        var state = PomodoroState()
        state.advance()
        #expect(state.sessionsCompleted == 1)
    }
    
    @Test func advance_fromBreak_doesNotIncrementSessionCount() {
        var state = PomodoroState()
        state.phase = .shortBreak
        state.sessionsCompleted = 2
        state.advance()
        #expect(state.sessionsCompleted == 2)
    }
    
    // MARK: - Duration
    
    @Test func totalDuration_focus_is25Minutes() {
        let state = PomodoroState()
        #expect(state.totalDuration() == 25 * 60)
    }
    
    @Test func totalDuration_shortBreak_is5Minutes() {
        var state = PomodoroState()
        state.phase = .shortBreak
        #expect(state.totalDuration() == 5 * 60)
    }
    
    @Test func totalDuration_longBreak_is15Minutes() {
        var state = PomodoroState()
        state.phase = .longBreak
        #expect(state.totalDuration() == 15 * 60)
    }
    
    // MARK: - Settings Reset
    
    @Test func settings_reset_restoresDefaults() {
        var state = PomodoroState()
        state.settings.focusDuration = 10
        state.settings.shortBreakDuration = 10
        state.settings = PomodoroSettings()
        #expect(state.settings.focusDuration == 25 * 60)
        #expect(state.settings.shortBreakDuration == 5 * 60)
    }
    
    // MARK: - Time Remaining After Advance
    
    @Test func advance_fromFocus_setsTimeRemainingToShortBreak() {
        var state = PomodoroState()
        state.advance()
        #expect(state.timeRemaining == state.settings.shortBreakDuration)
    }
    
    @Test func advance_afterFourSessions_setsTimeRemainingToLongBreak() {
        var state = PomodoroState()
        state.sessionsCompleted = 3
        state.advance()
        #expect(state.timeRemaining == state.settings.longBreakDuration)
    }
    
    // MARK: - Custom Settings
    
    @Test func customFocusDuration_reflectsInTotalDuration() {
        var state = PomodoroState()
        state.settings.focusDuration = 50 * 60
        #expect(state.totalDuration() == 50 * 60)
    }
    
    @Test func customSessionsBeforeLongBreak_triggersLongBreakCorrectly() {
        var state = PomodoroState()
        state.settings.sessionsBeforeLongBreak = 2
        state.sessionsCompleted = 1
        state.advance()
        #expect(state.phase == .longBreak)
    }
}
