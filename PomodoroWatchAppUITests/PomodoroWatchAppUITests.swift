//
//  PomodoroWatchAppUITests.swift
//  PomodoroWatchAppUITests
//
//  Created by Archit Joshi on 6/23/26.
//

import XCTest

final class PomodoroWatchAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch
    @MainActor
    func test_launch_transitionsToTimerView() {
        let timerLabel = app.staticTexts["timerLabel"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 3))
    }
    
    // MARK: - Timer Controls
    
    @MainActor
    func test_playButton_tapped_showsPauseButton() {
        let playPauseButton = app.buttons["playPauseButton"]
        XCTAssertTrue(playPauseButton.waitForExistence(timeout: 3))
        playPauseButton.tap()
        XCTAssertTrue(playPauseButton.exists)
    }
    
    @MainActor
    func test_resetButton_tapped_timerShowsFullDuration() {
        let timerLabel = app.staticTexts["timerLabel"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 3))
        app.buttons["playPauseButton"].tap()
        sleep(2)
        app.buttons["resetButton"].tap()
        XCTAssertEqual(timerLabel.label, "25:00")
    }
    
    @MainActor
    func test_skipButton_tapped_phaseChanges() {
        let phaseLabel = app.staticTexts["phaseLabel"]
        XCTAssertTrue(phaseLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(phaseLabel.label, "Focus")
        app.buttons["skipButton"].tap()
        XCTAssertEqual(phaseLabel.label, "Short Break")
    }
    
    // MARK: - Session Label
    
    @MainActor
    func test_initialSessionLabel_showsSession1() {
        let sessionLabel = app.staticTexts["sessionLabel"]
        XCTAssertTrue(sessionLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(sessionLabel.label, "Session 1")
    }
    
    @MainActor
    func test_skipFromFocus_sessionLabelShowsComplete() {
        let sessionLabel = app.staticTexts["sessionLabel"]
        XCTAssertTrue(sessionLabel.waitForExistence(timeout: 3))
        app.buttons["skipButton"].tap()
        XCTAssertEqual(sessionLabel.label, "Session 1 complete")
    }
    
    // MARK: - Performance
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
