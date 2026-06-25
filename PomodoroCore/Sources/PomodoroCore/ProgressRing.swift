//
//  ProgressRing.swift
//  PomodoroCore
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation
import SwiftUI

public struct ProgressRing: View {
    public let progress: Double
    public let color: Color
    
    private let lineWidth: CGFloat = 8
    
    public init(progress: Double, color: Color) {
        self.progress = progress
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 1 - progress, to: 1)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.7, color: .red)
        .frame(width: 150, height: 150)
}
