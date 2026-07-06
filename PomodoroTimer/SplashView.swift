//
//  SplashView.swift
//  PomodoroTimer
//
//  Created by Archit Joshi on 6/25/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🍅")
                .font(.system(size: 80))
            
            Text("Pomodoro")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Focus Timer")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .transition(.opacity)
    }
}

#Preview {
    SplashView()
}
