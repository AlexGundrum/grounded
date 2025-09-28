//
//  PanicLogModel.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import SwiftUI

// MARK: - Panic Attack Log Entry
struct PanicLogEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var cause: String
    var duration: TimeInterval // in minutes
    var avgHeartRate: Int
    var severity: PanicSeverity
    var notes: String
    
    init(date: Date, cause: String, duration: TimeInterval, avgHeartRate: Int, severity: PanicSeverity, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.cause = cause
        self.duration = duration
        self.avgHeartRate = avgHeartRate
        self.severity = severity
        self.notes = notes
    }
}

// MARK: - Panic Severity Levels
enum PanicSeverity: String, CaseIterable, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"
    
    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .extreme: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .mild: return "circle.fill"
        case .moderate: return "triangle.fill"
        case .severe: return "exclamationmark.triangle.fill"
        case .extreme: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Panic Log Manager
class PanicLogManager: ObservableObject {
    @Published var panicLogs: [PanicLogEntry] = []
    
    init() {
        setupDemoData()
    }
    
    private func setupDemoData() {
        let calendar = Calendar.current
        
        panicLogs = [
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                cause: "Work presentation stress",
                duration: 8.5,
                avgHeartRate: 142,
                severity: .moderate,
                notes: "Felt overwhelmed before the big presentation. Anchor helped me focus and stay calm."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                cause: "Crowded subway",
                duration: 12.0,
                avgHeartRate: 156,
                severity: .severe,
                notes: "Rush hour commute was overwhelming. Breathing exercises helped."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                cause: "Social anxiety at party",
                duration: 5.2,
                avgHeartRate: 128,
                severity: .mild,
                notes: "Quick grounding helped me stay calm."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                cause: "Financial stress",
                duration: 15.3,
                avgHeartRate: 148,
                severity: .severe,
                notes: "Budgeting session triggered anxiety. Anchor's breathing exercises were very helpful."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                cause: "Sleep deprivation",
                duration: 6.8,
                avgHeartRate: 135,
                severity: .moderate,
                notes: "Couldn't sleep, started panicking. Grounding techniques helped me relax."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -21, to: Date()) ?? Date(),
                cause: "Health anxiety",
                duration: 22.5,
                avgHeartRate: 162,
                severity: .extreme,
                notes: "Worried about symptoms. Anchor's emergency contacts feature was reassuring."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -28, to: Date()) ?? Date(),
                cause: "Relationship conflict",
                duration: 9.7,
                avgHeartRate: 139,
                severity: .moderate,
                notes: "Argument with partner. Deep breathing helped me calm down."
            ),
            PanicLogEntry(
                date: calendar.date(byAdding: .day, value: -35, to: Date()) ?? Date(),
                cause: "Job interview",
                duration: 4.2,
                avgHeartRate: 124,
                severity: .mild,
                notes: "Pre-interview nerves. Quick grounding exercise before going in."
            )
        ]
    }
    
    // MARK: - CRUD Operations
    
    func addPanicLog(_ entry: PanicLogEntry) {
        panicLogs.insert(entry, at: 0) // Add to beginning for newest first
    }
    
    func updatePanicLog(_ entry: PanicLogEntry) {
        if let index = panicLogs.firstIndex(where: { $0.id == entry.id }) {
            panicLogs[index] = entry
        }
    }
    
    func deletePanicLog(_ entry: PanicLogEntry) {
        panicLogs.removeAll { $0.id == entry.id }
    }
    
    // MARK: - Statistics
    
    func getAverageDuration() -> TimeInterval {
        guard !panicLogs.isEmpty else { return 0 }
        let totalDuration = panicLogs.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(panicLogs.count)
    }
    
    func getAverageHeartRate() -> Int {
        guard !panicLogs.isEmpty else { return 0 }
        let totalHeartRate = panicLogs.reduce(0) { $0 + $1.avgHeartRate }
        return totalHeartRate / panicLogs.count
    }
    
    func getMostCommonCause() -> String {
        let causes = panicLogs.map { $0.cause }
        let causeCounts = Dictionary(grouping: causes, by: { $0 })
        return causeCounts.max(by: { $0.value.count < $1.value.count })?.key ?? "Unknown"
    }
    
    func getSeverityDistribution() -> [PanicSeverity: Int] {
        var distribution: [PanicSeverity: Int] = [:]
        for severity in PanicSeverity.allCases {
            distribution[severity] = panicLogs.filter { $0.severity == severity }.count
        }
        return distribution
    }
}