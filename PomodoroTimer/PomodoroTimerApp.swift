//
//  PomodoroTimerApp.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/22/26.
//

import SwiftUI
import UserNotifications

@main
struct PomodoroTimerApp: App {
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }
}
