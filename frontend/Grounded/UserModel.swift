//
//  UserModel.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var profileImage: String // System image name
    var isOnline: Bool
    var lastActive: Date
    var emergencyContacts: [Contact]
    
    init(name: String, email: String, profileImage: String = "person.circle.fill", isOnline: Bool = true) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.profileImage = profileImage
        self.isOnline = isOnline
        self.lastActive = Date()
        self.emergencyContacts = []
    }
}

// MARK: - Contact Model
struct Contact: Identifiable, Codable {
    let id: UUID
    var name: String
    var relationship: String
    var phoneNumber: String
    var isEmergencyContact: Bool
    
    init(name: String, relationship: String, phoneNumber: String, isEmergencyContact: Bool = true) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.isEmergencyContact = isEmergencyContact
    }
}

// MARK: - User Data Manager
class UserDataManager: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User] = []
    @Published var isLoggedIn: Bool = false
    
    init() {
        // Default user for demo
        self.currentUser = User(
            name: "Demo User",
            email: "demo@grounded.app",
            profileImage: "person.circle.fill",
            isOnline: true
        )
        
        // Add fake friends for demo
        setupDemoData()
    }
    
    private func setupDemoData() {
        friends = [
            User(name: "Alex Gundrum", email: "alex@example.com", profileImage: "person.circle.fill", isOnline: true),
            User(name: "Kori Russell", email: "kori@example.com", profileImage: "person.circle.fill", isOnline: false),
            User(name: "Mom", email: "mom@example.com", profileImage: "heart.circle.fill", isOnline: true),
            User(name: "Tom Foolery", email: "tom@example.com", profileImage: "person.circle.fill", isOnline: true)
        ]
        
        // Add emergency contacts
        currentUser.emergencyContacts = [
            Contact(name: "Alex Gundrum", relationship: "Friend", phoneNumber: "+1 (555) 123-4567"),
            Contact(name: "Mom", relationship: "Family", phoneNumber: "+1 (555) 987-6543"),
            Contact(name: "Emergency Services", relationship: "Emergency", phoneNumber: "911")
        ]
    }
    
    // MARK: - CRUD Operations
    
    func login(email: String, password: String) -> Bool {
        // Fake login - always succeeds for demo
        isLoggedIn = true
        currentUser.isOnline = true
        currentUser.lastActive = Date()
        return true
    }
    
    func logout() {
        isLoggedIn = false
        currentUser.isOnline = false
        currentUser.lastActive = Date()
    }
    
    func updateProfile(name: String, email: String) {
        currentUser.name = name
        currentUser.email = email
        currentUser.lastActive = Date()
    }
    
    func addFriend(_ user: User) {
        if !friends.contains(where: { $0.id == user.id }) {
            friends.append(user)
        }
    }
    
    func removeFriend(_ user: User) {
        friends.removeAll { $0.id == user.id }
    }
    
    func addEmergencyContact(_ contact: Contact) {
        currentUser.emergencyContacts.append(contact)
    }
    
    func removeEmergencyContact(_ contact: Contact) {
        currentUser.emergencyContacts.removeAll { $0.id == contact.id }
    }
    
    func updateFriendStatus(_ user: User, isOnline: Bool) {
        if let index = friends.firstIndex(where: { $0.id == user.id }) {
            friends[index].isOnline = isOnline
            friends[index].lastActive = Date()
        }
    }
}