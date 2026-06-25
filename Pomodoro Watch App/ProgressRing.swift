//
//  ProgressRing.swift
//  PomodoroApp
//
//  Created by Archit Joshi on 6/23/26.
//

import Foundation
import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    
    private let lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 1 - progress, to: 1)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // start from top
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.7, color: .green)
        .frame(width: 150, height: 150)
}
