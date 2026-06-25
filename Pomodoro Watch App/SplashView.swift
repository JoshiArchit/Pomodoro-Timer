//
//  SplashView.swift
//  PomodoroApp
//
//  Created by Archit Joshi on 6/23/26.
//

import Foundation
import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("🍅")
                .font(.system(size: 48))
            
            Text("Pomodoro")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Focus Timer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .transition(.opacity)
        .accessibilityIdentifier("splashView")
    }
}

#Preview {
    SplashView()
}
