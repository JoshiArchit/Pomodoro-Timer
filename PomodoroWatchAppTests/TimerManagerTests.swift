//
//  TimerManagerTests.swift
//  PomodoroWatchAppTests
//
//  Created by Archit Joshi on 6/24/26.
//

import Testing
internal import PomodoroCore
@testable import PomodoroWatchApp

struct TimerManagerTests {
    
    // MARK: - Initial State
    
    @Test func initialState_isNotRunning() {
        let manager = TimerManager()
        #expect(manager.state.isRunning == false)
    }
    
    @Test func initialState_phaseIsFocus() {
        let manager = TimerManager()
        #expect(manager.state.phase == .focus)
    }
    
    @Test func initialState_timeRemainingIs25Minutes() {
        let manager = TimerManager()
        #expect(manager.state.timeRemaining == 25 * 60)
    }
    
    // MARK: - Start / Pause
    
    @Test func start_setsIsRunningTrue() {
        let manager = TimerManager()
        manager.start()
        #expect(manager.state.isRunning == true)
    }
    
    @Test func pause_setsIsRunningFalse() {
        let manager = TimerManager()
        manager.start()
        manager.pause()
        #expect(manager.state.isRunning == false)
    }
    
    // MARK: - Reset
    
    @Test func reset_setsTimeRemainingToTotalDuration() {
        let manager = TimerManager()
        manager.state.timeRemaining = 10
        manager.reset()
        #expect(manager.state.timeRemaining == manager.state.totalDuration())
    }
    
    @Test func reset_setsIsRunningFalse() {
        let manager = TimerManager()
        manager.start()
        manager.reset()
        #expect(manager.state.isRunning == false)
    }
    
    // MARK: - Skip
    
    @Test func skip_fromFocus_goesToShortBreak() {
        let manager = TimerManager()
        manager.skip()
        #expect(manager.state.phase == .shortBreak)
    }
    
    @Test func skip_setsIsRunningFalse() {
        let manager = TimerManager()
        manager.start()
        manager.skip()
        #expect(manager.state.isRunning == false)
    }
    
    @Test func skip_fromFocus_incrementsSessionCount() {
        let manager = TimerManager()
        manager.skip()
        #expect(manager.state.sessionsCompleted == 1)
    }
    
    // MARK: - Settings
    
    @Test func settings_change_reflectsInTimeRemaining() {
        let manager = TimerManager()
        manager.state.settings.focusDuration = 50 * 60
        manager.reset()
        #expect(manager.state.timeRemaining == 50 * 60)
    }
}
