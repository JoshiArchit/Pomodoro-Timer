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
    public let wasSkipped: Bool
    
    public init(phase: Phase, duration: TimeInterval, completedAt: Date = Date(), wasSkipped: Bool = false) {
        self.id = UUID()
        self.phase = phase
        self.duration = duration
        self.completedAt = completedAt
        self.wasSkipped = wasSkipped
    }
    
    public var durationInMinutes: Int {
        Int(duration / 60)
    }
}
