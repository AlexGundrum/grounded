//
//  ProfileView.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var showingEmergencyContacts = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 20) {
                        // Profile Image
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.seaGreen, .oceanBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: userDataManager.currentUser.profileImage)
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .seaGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text(userDataManager.currentUser.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.anchorSilver)
                            
                            Text(userDataManager.currentUser.email)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.seafoam)
                            
                            // Online Status
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(userDataManager.currentUser.isOnline ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                
                                Text(userDataManager.currentUser.isOnline ? "Online" : "Offline")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.seafoam)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        ProfileActionButton(
                            icon: "person.circle",
                            title: "Edit Profile",
                            action: { showingEditProfile = true }
                        )
                        
                        ProfileActionButton(
                            icon: "heart.circle",
                            title: "Emergency Contacts",
                            subtitle: "\(userDataManager.currentUser.emergencyContacts.count) contacts",
                            action: { showingEmergencyContacts = true }
                        )
                        
                        ProfileActionButton(
                            icon: "person.2.circle",
                            title: "Friends",
                            subtitle: "\(userDataManager.friends.count) friends",
                            action: { }
                        )
                        
                        ProfileActionButton(
                            icon: "gear.circle",
                            title: "Settings",
                            action: { }
                        )
                        
                        ProfileActionButton(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            isDestructive: true,
                            action: { 
                                userDataManager.logout()
                                dismiss()
                            }
                        )
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 20)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.seaGreen)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userDataManager: userDataManager)
        }
        .sheet(isPresented: $showingEmergencyContacts) {
            EmergencyContactsView(userDataManager: userDataManager)
        }
    }
}

// MARK: - Profile Action Button
struct ProfileActionButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDestructive ? .red : .seaGreen)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.anchorSilver)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.seafoam)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.seafoam)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.seaGreen.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.oceanDeep.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18))
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(
                LinearGradient(
                    colors: [.deepCurrent.opacity(0.9), .oceanDeep.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.seaGreen)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userDataManager.updateProfile(name: name, email: email)
                        dismiss()
                    }
                    .foregroundColor(.seaGreen)
                }
            }
        }
        .onAppear {
            name = userDataManager.currentUser.name
            email = userDataManager.currentUser.email
        }
    }
}

// MARK: - Emergency Contacts View
struct EmergencyContactsView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(userDataManager.currentUser.emergencyContacts) { contact in
                    HStack(spacing: 15) {
                        Image(systemName: contact.isEmergencyContact ? "heart.circle.fill" : "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(contact.isEmergencyContact ? .red : .seaGreen)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.anchorSilver)
                            
                            Text(contact.relationship)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.seafoam)
                            
                            Text(contact.phoneNumber)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.seafoam)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            .background(
                LinearGradient(
                    colors: [.deepCurrent.opacity(0.9), .oceanDeep.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Emergency Contacts")
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

#Preview {
    ProfileView(userDataManager: UserDataManager())
}