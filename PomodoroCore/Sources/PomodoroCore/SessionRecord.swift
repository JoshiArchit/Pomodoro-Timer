//
//  File.swift
//  PomodoroCore
//
//  Created by Archit Joshi on 6/25/26.
//

import Foundation

public struct SessionRecord: Identifiable, Codable {
    public let id: UUID
    public let phase: Phase
    public let duration: TimeInterval
    public let completedAt: Date
    
    public init(phase: Phase, duration: TimeInterval, completedAt: Date = Date()) {
        self.id = UUID()
        self.phase = phase
        self.duration = duration
        self.completedAt = completedAt
    }
    
    public var durationInMinutes: Int {
        Int(duration / 60)
    }
}
