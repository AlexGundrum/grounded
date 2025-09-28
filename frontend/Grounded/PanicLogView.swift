//
//  PanicLogView.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI

struct PanicLogView: View {
    @ObservedObject var panicLogManager: PanicLogManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Statistics Header
                    VStack(spacing: 15) {
                        Text("Panic Attack History")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.anchorSilver)
                        
                        // Quick Stats
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Total Episodes",
                                value: "\(panicLogManager.panicLogs.count)",
                                icon: "waveform.path.ecg",
                                color: .seaGreen
                            )
                            
                            StatCard(
                                title: "Avg Duration",
                                value: String(format: "%.1f min", panicLogManager.getAverageDuration()),
                                icon: "clock",
                                color: .oceanBlue
                            )
                            
                            StatCard(
                                title: "Avg Heart Rate",
                                value: "\(panicLogManager.getAverageHeartRate()) BPM",
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Log Entries
                    VStack(spacing: 12) {
                        ForEach(panicLogManager.panicLogs) { entry in
                            PanicLogEntryView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            .background(
                LinearGradient(
                    colors: [.deepCurrent.opacity(0.9), .oceanDeep.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.seaGreen)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.anchorSilver)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.seafoam)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Panic Log Entry View
struct PanicLogEntryView: View {
    let entry: PanicLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                // Severity Indicator
                HStack(spacing: 6) {
                    Image(systemName: entry.severity.icon)
                        .font(.caption)
                        .foregroundColor(entry.severity.color)
                    
                    Text(entry.severity.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(entry.severity.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(entry.severity.color.opacity(0.2))
                )
                
                Spacer()
                
                // Date
                Text(entry.date, style: .date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.seafoam)
            }
            
            // Cause
            Text(entry.cause)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.anchorSilver)
            
            // Details Row
            HStack(spacing: 20) {
                DetailItem(icon: "clock", text: String(format: "%.1f min", entry.duration))
                DetailItem(icon: "heart.fill", text: "\(entry.avgHeartRate) BPM")
            }
            
            // Notes
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.seafoam)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.seaGreen.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.seaGreen)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.anchorSilver)
        }
    }
}

// MARK: - Flow Layout for Objects
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
}

struct FlowResult {
    let size: CGSize
    let positions: [CGPoint]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var positions: [CGPoint] = []
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + subviewSize.width > maxWidth && currentPosition.x > 0 {
                // Move to next line
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(currentPosition)
            lineHeight = max(lineHeight, subviewSize.height)
            currentPosition.x += subviewSize.width + spacing
        }
        
        self.positions = positions
        self.size = CGSize(
            width: maxWidth,
            height: currentPosition.y + lineHeight
        )
    }
}

#Preview {
    PanicLogView(panicLogManager: PanicLogManager())
}