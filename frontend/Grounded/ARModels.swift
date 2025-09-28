//
//  ARModels.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import SwiftUI

// MARK: - AR Object Model
struct ARObject: Identifiable, Decodable {
    let id: UUID
    let label: String
    let box_x: Double
    let box_y: Double
    let color: String?
    
    init(label: String, box_x: Double, box_y: Double, color: String?) {
        self.id = UUID()
        self.label = label
        self.box_x = box_x
        self.box_y = box_y
        self.color = color
    }
    
    // Computed properties for easier access
    var normalizedX: Double { box_x }
    var normalizedY: Double { box_y }
    
    // Color mapping for visual feedback - Forest style
    var displayColor: Color {
        switch color?.lowercased() {
        case "red":
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Forest red
        case "blue":
            return Color(red: 0.2, green: 0.4, blue: 0.8) // Forest blue
        case "green":
            return Color(red: 0.2, green: 0.6, blue: 0.2) // Forest green
        case "yellow":
            return Color(red: 0.9, green: 0.7, blue: 0.1) // Forest yellow
        case "orange":
            return Color(red: 0.9, green: 0.5, blue: 0.1) // Forest orange
        case "purple":
            return Color(red: 0.5, green: 0.2, blue: 0.7) // Forest purple
        case "brown":
            return Color(red: 0.4, green: 0.3, blue: 0.2) // Forest brown
        default:
            return Color(red: 0.2, green: 0.6, blue: 0.2) // Default forest green
        }
    }
}

// MARK: - AR Response Model
struct ARResponse: Decodable {
    let audioBase64: String?
    let responseText: String?
    let ar_data: [ARObject]?
    
    // Computed properties for easier access
    var hasAudio: Bool {
        return audioBase64 != nil && !audioBase64!.isEmpty
    }
    
    var hasARData: Bool {
        return ar_data != nil && !ar_data!.isEmpty
    }
    
    var hasResponseText: Bool {
        return responseText != nil && !responseText!.isEmpty
    }
}

// MARK: - AR Overlay State
class AROverlayState: ObservableObject {
    @Published var arObjects: [ARObject] = []
    @Published var isVisible: Bool = false
    @Published var currentInstruction: String = ""
    @Published var showDirectionalArrow: Bool = false
    @Published var arrowTarget: ARObject?
    
    func updateARObjects(_ objects: [ARObject]) {
        arObjects = objects
        isVisible = !objects.isEmpty
    }
    
    func showInstruction(_ instruction: String, targetObject: ARObject? = nil) {
        currentInstruction = instruction
        arrowTarget = targetObject
        showDirectionalArrow = targetObject != nil
    }
    
    func clearOverlay() {
        arObjects = []
        isVisible = false
        currentInstruction = ""
        showDirectionalArrow = false
        arrowTarget = nil
    }
}

// MARK: - Mock AR Data for Testing
extension ARObject {
    static let mockObjects: [ARObject] = [
        ARObject(label: "table", box_x: 0.45, box_y: 0.60, color: "brown"),
        ARObject(label: "red lamp", box_x: 0.50, box_y: 0.30, color: "red"),
        ARObject(label: "window", box_x: 0.20, box_y: 0.25, color: "blue"),
        ARObject(label: "chair", box_x: 0.70, box_y: 0.55, color: "brown"),
        ARObject(label: "plant", box_x: 0.80, box_y: 0.40, color: "green")
    ]
    
    static let mockResponse: ARResponse = ARResponse(
        audioBase64: nil,
        responseText: "Look at the table, what color is the red lamp?",
        ar_data: mockObjects
    )
}