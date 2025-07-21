import SwiftUI

struct MoreView: View {
    let userData: UserData?
    
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userData?.name ?? "User")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(userData?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // My Diagnosis Section
                Section("My Diagnosis") {
                    NavigationLink(destination: Text("Diagnosis Screen")) {
                        MoreRow(icon: "stethoscope", title: "My Diagnosis", subtitle: "View your IBD diagnosis")
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    NavigationLink(destination: Text("Profile Settings")) {
                        MoreRow(icon: "person.fill", title: "Profile", subtitle: "Edit your profile")
                    }
                    
                    NavigationLink(destination: Text("Notifications Settings")) {
                        MoreRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage notifications")
                    }
                    
                    NavigationLink(destination: Text("Privacy Settings")) {
                        MoreRow(icon: "lock.fill", title: "Privacy", subtitle: "Privacy settings")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: Text("Help & FAQ")) {
                        MoreRow(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help and answers")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        MoreRow(icon: "envelope.fill", title: "Contact Support", subtitle: "Get in touch with us")
                    }
                    
                    NavigationLink(destination: Text("About IBDPal")) {
                        MoreRow(icon: "info.circle.fill", title: "About", subtitle: "Learn about IBDPal")
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        MoreRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "Sign out of your account")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    // Handle sign out
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MoreView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", token: "token"))
} 