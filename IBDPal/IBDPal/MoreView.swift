import SwiftUI

struct MoreView: View {
    let userData: UserData?
    let onSignOut: () -> Void
    
    @State private var showingLogoutAlert = false
    @State private var isSigningOut = false
    @State private var showingDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showingDeleteConfirmation = false
    
    // Updated API URL to match your backend
    private let apiBaseURL = AppConfig.apiBaseURL
    
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
                    NavigationLink(destination: MyDiagnosisView(userData: userData)) {
                        MoreRow(icon: "stethoscope", title: "My Diagnosis", subtitle: "View your IBD diagnosis")
                    }
                    
                    NavigationLink(destination: MicronutrientProfileView(userData: userData)) {
                        MoreRow(icon: "pills.fill", title: "Nutrition Profile", subtitle: "Age, weight & micronutrients for personalized nutrition")
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    NavigationLink(destination: ProfileView(userData: userData)) {
                        MoreRow(icon: "person.fill", title: "Profile", subtitle: "Edit your profile")
                    }
                    
                    NavigationLink(destination: MoreRemindersView(userData: userData)) {
                        MoreRow(icon: "bell.fill", title: "Reminders", subtitle: "Schedule and manage reminders")
                    }
                    
                    NavigationLink(destination: PrivacyView()) {
                        MoreRow(icon: "lock.fill", title: "Privacy", subtitle: "Privacy settings")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpFAQView()) {
                        MoreRow(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help and answers")
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        MoreRow(icon: "envelope.fill", title: "Contact Support", subtitle: "Get in touch with us")
                    }
                    
                    NavigationLink(destination: FeedbackView(userData: userData)) {
                        MoreRow(icon: "star.fill", title: "Feedback", subtitle: "Share your experience and suggestions")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        MoreRow(icon: "info.circle.fill", title: "About", subtitle: "Learn about IBDPal")
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            MoreRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "Sign out of your account")
                                .foregroundColor(.red)
                            
                            if isSigningOut {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSigningOut)
                    
                    Button(action: {
                        showingDeleteAccountAlert = true
                    }) {
                        HStack {
                            MoreRow(icon: "trash.fill", title: "Delete Account", subtitle: "Permanently delete your account and data")
                                .foregroundColor(.red)
                            
                            if isDeletingAccount {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isDeletingAccount)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .alert("Confirm Account Deletion", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    handleDeleteAccount()
                }
            } message: {
                Text("Are you absolutely sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.")
            }
        }
    }
    
    private func handleSignOut() {
        guard let userData = userData else {
            // If no user data, just sign out locally
            onSignOut()
            return
        }
        
        isSigningOut = true
        print("🔐 [MoreView] Starting sign out process...")
        
        // Call server logout endpoint
        guard let url = URL(string: "\(apiBaseURL)\(AppConfig.Endpoints.logout)") else {
            print("❌ [MoreView] Invalid logout URL")
            isSigningOut = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSigningOut = false
                
                if let error = error {
                    print("❌ [MoreView] Logout network error: \(error)")
                    // Even if server logout fails, sign out locally
                    onSignOut()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 [MoreView] Logout HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        print("✅ [MoreView] Server logout successful")
                    } else {
                        print("⚠️ [MoreView] Server logout returned status: \(httpResponse.statusCode)")
                    }
                }
                
                // Always sign out locally regardless of server response
                onSignOut()
            }
        }.resume()
    }
    
    private func handleDeleteAccount() {
        guard let userData = userData else {
            print("❌ [MoreView] No user data available for account deletion")
            return
        }
        
        isDeletingAccount = true
        print("🗑️ [MoreView] Starting account deletion process...")
        
        // Call server delete account endpoint
        guard let url = URL(string: "\(apiBaseURL)/api/users/account") else {
            print("❌ [MoreView] Invalid delete account URL")
            isDeletingAccount = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isDeletingAccount = false
                
                if let error = error {
                    print("❌ [MoreView] Delete account network error: \(error)")
                    // Show error alert
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 [MoreView] Delete account HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        print("✅ [MoreView] Account deletion successful")
                        // Sign out locally after successful deletion
                        onSignOut()
                    } else {
                        print("⚠️ [MoreView] Account deletion failed with status: \(httpResponse.statusCode)")
                        // Show error alert
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userData: UserData?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Information Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Profile Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(spacing: 15) {
                        // First Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            TextField("Enter your first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .disabled(isLoading)
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            TextField("Enter your last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .disabled(isLoading)
                        }
                        
                        // Email (Read-only)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            TextField("Email address", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.gray)
                        }
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                .disabled(isLoading)
                        }
                        
                        Button(action: updateProfile) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Update Profile")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Change Password Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Change Password")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(spacing: 15) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Current Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            HStack {
                                if showCurrentPassword {
                                    TextField("Enter current password", text: $currentPassword)
                                } else {
                                    SecureField("Enter current password", text: $currentPassword)
                                }
                                
                                Button(action: { showCurrentPassword.toggle() }) {
                                    Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isLoading)
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 5) {
                            Text("New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            HStack {
                                if showNewPassword {
                                    TextField("Enter new password", text: $newPassword)
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                }
                                
                                Button(action: { showNewPassword.toggle() }) {
                                    Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isLoading)
                        }
                        
                        // Confirm New Password
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Confirm New Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isLoading)
                        }
                        
                        Button(action: changePassword) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Change Password")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadUserData() {
        
        // Parse name into first and last name
        let nameComponents = userData?.name?.components(separatedBy: " ") ?? []
        firstName = nameComponents.first ?? ""
        lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        email = userData?.email ?? ""
        phoneNumber = userData?.phoneNumber ?? ""
    }
    
    private func updateProfile() {
        
        isLoading = true
        
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        guard !fullName.isEmpty else {
            showError("Invalid Name", "Please enter your first and last name.")
            isLoading = false
            return
        }
        
        let requestData: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "phone_number": phoneNumber
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/api/users/profile") else {
            showError("Network Error", "Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            showError("Network Error", "Failed to prepare request data")
            isLoading = false
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError("Network Error", error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        showSuccess("Profile Updated", "Your profile has been updated successfully.")
                    } else {
                        showError("Update Failed", "Failed to update profile. Please try again.")
                    }
                }
            }
        }.resume()
    }
    
    private func changePassword() {
        
        isLoading = true
        
        // Validate passwords
        guard !currentPassword.isEmpty else {
            showError("Invalid Input", "Please enter your current password.")
            isLoading = false
            return
        }
        
        guard newPassword.count >= 8 else {
            showError("Invalid Password", "New password must be at least 8 characters long.")
            isLoading = false
            return
        }
        
        guard newPassword == confirmPassword else {
            showError("Password Mismatch", "New passwords do not match.")
            isLoading = false
            return
        }
        
        let requestData: [String: Any] = [
            "current_password": currentPassword,
            "new_password": newPassword
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/api/users/password") else {
            showError("Network Error", "Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            showError("Network Error", "Failed to prepare request data")
            isLoading = false
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError("Network Error", error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        showSuccess("Password Changed", "Your password has been changed successfully.")
                        // Clear password fields
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    } else {
                        showError("Password Change Failed", "Failed to change password. Please check your current password and try again.")
                    }
                }
            }
        }.resume()
    }
    
    private func showError(_ title: String, _ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        successMessage = message
        showSuccessAlert = true
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Introduction
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. INTRODUCTION")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("This Privacy Policy describes how IBDPal ('we', 'our', or 'us') collects, uses, and protects your personal information when you use our mobile application. We are committed to protecting your privacy and ensuring the security of your personal data.")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Information We Collect
                VStack(alignment: .leading, spacing: 8) {
                    Text("2. INFORMATION WE COLLECT")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("Personal Information:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Name (first and last name)")
                        Text("• Email address")
                        Text("• Account credentials")
                        Text("• Profile information")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("Health and Usage Data:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Food intake and nutrition data")
                        Text("• Symptom tracking information")
                        Text("• Medication records")
                        Text("• Health metrics and measurements")
                        Text("• App usage patterns and preferences")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // How We Use Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("3. HOW WE USE YOUR INFORMATION")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• To provide and maintain the application's functionality")
                        Text("• To personalize your experience and provide relevant content")
                        Text("• To analyze usage patterns and improve our services")
                        Text("• To communicate with you about your account and updates")
                        Text("• To ensure the security and integrity of our platform")
                        Text("• To comply with legal obligations and regulations")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Data Security
                VStack(alignment: .leading, spacing: 8) {
                    Text("4. DATA SECURITY")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Encryption of data in transit and at rest")
                        Text("• Secure authentication and authorization protocols")
                        Text("• Regular security assessments and updates")
                        Text("• Access controls and user authentication")
                        Text("• Secure data storage and backup procedures")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Data Sharing
                VStack(alignment: .leading, spacing: 8) {
                    Text("5. DATA SHARING AND DISCLOSURE")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("We do not sell, trade, or otherwise transfer your personal information to third parties without your explicit consent, except in the following circumstances:")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• With your explicit consent and authorization")
                        Text("• To comply with legal requirements or court orders")
                        Text("• To protect our rights, property, or safety")
                        Text("• To service providers who assist in app operations")
                        Text("• In case of business transfer or merger")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Your Rights
                VStack(alignment: .leading, spacing: 8) {
                    Text("6. YOUR RIGHTS AND CHOICES")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("You have the following rights regarding your personal information:")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Access and review your personal data")
                        Text("• Request correction of inaccurate information")
                        Text("• Request deletion of your personal data")
                        Text("• Object to processing of your data")
                        Text("• Request data portability")
                        Text("• Withdraw consent at any time")
                        Text("• Opt-out of marketing communications")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Health Data Specific
                VStack(alignment: .leading, spacing: 8) {
                    Text("7. HEALTH DATA PROTECTION")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("Given the sensitive nature of health information, we implement additional safeguards:")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Enhanced encryption for health-related data")
                        Text("• Strict access controls and audit logging")
                        Text("• Compliance with health data regulations")
                        Text("• Regular security assessments")
                        Text("• Limited data access to authorized personnel only")
                    }
                    .font(.body)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Contact Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("8. CONTACT US")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("If you have any questions about this Privacy Policy or our data practices, please contact us through the application's support channels or at our designated privacy contact.")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
            }
            .padding()
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
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
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Help & FAQ View
struct HelpFAQView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help & FAQ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("Learn how IBDPal helps you manage your IBD journey")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Daily Log Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Daily Log")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is it?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your comprehensive daily tracking tool for monitoring all aspects of your IBD management.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Key Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Meal Journal: Track what you eat and get automatic nutrition analysis")
                            Text("• Medication Tracking: Monitor adherence and set reminders")
                            Text("• Bowel Health: Record frequency, consistency, and symptoms")
                            Text("• Symptom Monitoring: Track pain, fatigue, and other symptoms")
                            Text("• Lifestyle Factors: Monitor sleep, stress, and hydration")
                        }
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Why it's important:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        Text("Consistent daily monitoring helps identify patterns, triggers, and early warning signs. This data enables your healthcare team to make informed treatment decisions and helps you achieve and maintain remission.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Trends Section (formerly Discover)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Trends")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is it?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your personal health analytics dashboard that transforms your daily data into actionable insights.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Key Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Trend Analysis: Visualize patterns in your symptoms and nutrition")
                            Text("• Health Metrics: Track key indicators over time")
                            Text("• Nutrition Insights: Monitor dietary patterns and recommendations")
                            Text("• Symptom Correlation: Identify relationships between diet and symptoms")
                            Text("• Progress Tracking: See your improvement over weeks and months")
                        }
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Why it's important:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        Text("Understanding your health patterns is crucial for achieving remission. The Trends tab helps you identify what works for your body, recognize early warning signs, and make informed decisions about your diet and lifestyle.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Connect Section (formerly Search)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Connect")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is it?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your intelligent food database and nutrition analyzer to help you make informed dietary choices.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Key Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Food Database: Comprehensive IBD-friendly food information")
                            Text("• Nutrition Analysis: Detailed breakdown of calories, protein, carbs, fiber")
                            Text("• FODMAP Filtering: Identify high and low FODMAP foods")
                            Text("• Smart Search: Find foods by name, ingredients, or nutrition")
                            Text("• Personal Recommendations: Get suggestions based on your health data")
                        }
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Why it's important:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        Text("Diet plays a crucial role in IBD management. The Connect feature helps you understand how different foods affect your body, make informed choices, and maintain a balanced diet that supports your journey to remission.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // More Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Text("More")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is it?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your account management and support center for personalizing your IBDPal experience.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Key Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Profile Management: Update your personal information")
                            Text("• Privacy Settings: Control your data and privacy preferences")
                            Text("• Help & Support: Access resources and contact support")
                            Text("• Account Security: Manage passwords and account settings")
                            Text("• App Information: Learn about IBDPal and updates")
                        }
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Why it's important:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .padding(.top, 8)
                        
                        Text("Managing your account and understanding your privacy rights ensures you have full control over your health data. The More section helps you customize your experience and get support when you need it.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // FAQ Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Frequently Asked Questions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FAQItem(
                            question: "How often should I log my data?",
                            answer: "We recommend logging daily for the best results. Even if you miss a day, continue logging - consistency over time is more important than perfect daily records."
                        )
                        
                        FAQItem(
                            question: "Is my health data secure?",
                            answer: "Yes, your data is encrypted and stored securely. We follow strict privacy standards and never share your personal health information without your explicit consent."
                        )
                        
                        FAQItem(
                            question: "Can I share my data with my doctor?",
                            answer: "Yes! You can export your data or share insights with your healthcare team. This helps them make more informed treatment decisions."
                        )
                        
                        FAQItem(
                            question: "What if I notice a pattern in my symptoms?",
                            answer: "Use the Discover tab to analyze patterns. If you notice concerning trends, discuss them with your healthcare provider. IBDPal is a tool to support, not replace, medical advice."
                        )
                        
                        FAQItem(
                            question: "How does IBDPal help with remission?",
                            answer: "By tracking your daily patterns, IBDPal helps identify triggers, monitor treatment effectiveness, and provide insights that support your journey to remission. Regular monitoring is key to successful IBD management."
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ Item Component
struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            Text(answer)
                .font(.body)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .cornerRadius(8)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.ibdPrimary)
                    
                    Text("IBDPal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Your Personal IBD Management Companion")
                        .font(.title3)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // App Description
                VStack(alignment: .leading, spacing: 16) {
                    Text("About IBDPal")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("IBDPal is a comprehensive mobile application designed to help individuals with Inflammatory Bowel Disease (IBD) manage their condition effectively. Our app provides tools for tracking symptoms, monitoring nutrition, managing medications, and connecting with the IBD community.")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                        .lineSpacing(4)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Key Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Symptom Tracking", description: "Monitor your daily symptoms and track patterns over time")
                        FeatureRow(icon: "fork.knife", title: "Nutrition Management", description: "Track your meals and analyze nutritional intake")
                        FeatureRow(icon: "pills.fill", title: "Medication Reminders", description: "Never miss your medications with smart reminders")
                        FeatureRow(icon: "brain.head.profile", title: "Stress & Sleep Tracking", description: "Monitor lifestyle factors that affect your IBD")
                        FeatureRow(icon: "chart.bar.fill", title: "Trends & Insights", description: "Visualize your data and gain insights into your condition")
                        FeatureRow(icon: "person.3.fill", title: "Community Support", description: "Connect with others and access educational resources")
                    }
                }
                
                // Company Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Medivue")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("IBDPal is developed by Medivue, a registered nonprofit organization in the State of North Carolina. Our mission is to improve the quality of life for individuals living with chronic health conditions through innovative technology solutions.")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                        .lineSpacing(4)
                }
                
                // Legal Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Legal Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        LegalSection(title: "Copyright", content: "© 2024 Medivue. All rights reserved.\n\nIBDPal and all associated content, features, and functionality are owned by Medivue, a registered nonprofit organization in the State of North Carolina.")
                        
                        LegalSection(title: "Patent Rights", content: "This application and its underlying technology may be protected by various patents and patent applications. All patent rights are owned by Medivue.")
                        
                        LegalSection(title: "Trademarks", content: "IBDPal is a trademark of Medivue. All other trademarks and service marks are the property of their respective owners.")
                        
                        LegalSection(title: "Privacy & Terms", content: "Your privacy is important to us. Please review our Privacy Policy and Terms of Service for information about how we collect, use, and protect your data.")
                    }
                }
                
                // Contact Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ContactRow(icon: "building.2.fill", text: "Medivue")
                        ContactRow(icon: "location.fill", text: "North Carolina, USA")
                        ContactRow(icon: "envelope.fill", text: "support@medivue.org")
                        ContactRow(icon: "globe", text: "www.medivue.org")
                    }
                }
                
                // Version Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.ibdSecondaryText)
                    
                    Text("Build Date: \(getBuildDate())")
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.ibdBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getBuildDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.ibdPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
                    .lineLimit(3)
            }
            
            Spacer()
        }
    }
}

struct LegalSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.ibdPrimaryText)
            
            Text(content)
                .font(.caption)
                .foregroundColor(.ibdSecondaryText)
                .lineSpacing(2)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(8)
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.ibdPrimary)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.ibdSecondaryText)
            
            Spacer()
        }
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @State private var showingEmailComposer = false
    @State private var showingPhoneCall = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.ibdPrimary)
                    
                    Text("Contact Support")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("We're here to help you with any questions or concerns about IBDPal")
                        .font(.title3)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // Support Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("How Can We Help?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(spacing: 12) {
                        SupportOptionCard(
                            icon: "envelope.fill",
                            title: "Email Support",
                            description: "Send us an email for general inquiries, bug reports, or feature requests",
                            action: "Send Email",
                            color: .blue
                        ) {
                            showingEmailComposer = true
                        }
                        
                        SupportOptionCard(
                            icon: "phone.fill",
                            title: "Phone Support",
                            description: "Call us for urgent issues or if you prefer to speak with someone directly",
                            action: "Call Now",
                            color: .green
                        ) {
                            showingPhoneCall = true
                        }
                        
                        SupportOptionCard(
                            icon: "questionmark.circle.fill",
                            title: "Help & FAQ",
                            description: "Browse our frequently asked questions and help documentation",
                            action: "View FAQ",
                            color: .orange
                        ) {
                            // This will be handled by the existing Help & FAQ navigation
                        }
                    }
                }
                
                // Company Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Medivue")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("IBDPal is developed by Medivue, a registered nonprofit organization in the State of North Carolina. Our mission is to improve the quality of life for individuals living with chronic health conditions through innovative technology solutions.")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                        .lineSpacing(4)
                }
                
                // Contact Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ContactInfoCard(
                            icon: "building.2.fill",
                            title: "Company",
                            detail: "Medivue",
                            subtitle: "Registered Nonprofit Organization"
                        )
                        
                        ContactInfoCard(
                            icon: "location.fill",
                            title: "Location",
                            detail: "North Carolina, USA",
                            subtitle: "State of North Carolina"
                        )
                        
                        ContactInfoCard(
                            icon: "envelope.fill",
                            title: "Email",
                            detail: "support@medivue.org",
                            subtitle: "General inquiries and support"
                        )
                        
                        ContactInfoCard(
                            icon: "globe",
                            title: "Website",
                            detail: "www.medivue.org",
                            subtitle: "Learn more about our organization"
                        )
                    }
                }
                
                // Response Time
                VStack(alignment: .leading, spacing: 16) {
                    Text("Response Times")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ResponseTimeCard(
                            type: "Email Support",
                            time: "24-48 hours",
                            description: "We typically respond to emails within 1-2 business days"
                        )
                        
                        ResponseTimeCard(
                            type: "Urgent Issues",
                            time: "Same day",
                            description: "Critical issues are prioritized and addressed as quickly as possible"
                        )
                        
                        ResponseTimeCard(
                            type: "Feature Requests",
                            time: "1-2 weeks",
                            description: "We review all feature requests and provide updates on implementation"
                        )
                    }
                }
                
                // Support Hours
                VStack(alignment: .leading, spacing: 16) {
                    Text("Support Hours")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.ibdPrimary)
                                .frame(width: 20)
                            
                            Text("Monday - Friday: 9:00 AM - 6:00 PM EST")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.ibdPrimary)
                                .frame(width: 20)
                            
                            Text("Saturday: 10:00 AM - 4:00 PM EST")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.ibdPrimary)
                                .frame(width: 20)
                            
                            Text("Sunday: Closed")
                                .font(.subheadline)
                                .foregroundColor(.ibdSecondaryText)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.ibdBackground)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Email Support", isPresented: $showingEmailComposer) {
            Button("Open Mail App") {
                openEmailApp()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to open your email app to send us a message?")
        }
        .alert("Phone Support", isPresented: $showingPhoneCall) {
            Button("Call Support") {
                openPhoneApp()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to call our support line?")
        }
    }
    
    private func openEmailApp() {
        if let url = URL(string: "mailto:support@medivue.org") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhoneApp() {
        // For now, we'll use a placeholder number
        // In production, this would be the actual support phone number
        if let url = URL(string: "tel:+1-800-MEDIVUE") {
            UIApplication.shared.open(url)
        }
    }
}

struct SupportOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.ibdSecondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(action)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color.ibdSurfaceBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactInfoCard: View {
    let icon: String
    let title: String
    let detail: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.ibdPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(detail)
                    .font(.headline)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(12)
    }
}

struct ResponseTimeCard: View {
    let type: String
    let time: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ibdPrimaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.ibdSecondaryText)
            }
            
            Spacer()
            
            Text(time)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.ibdPrimary)
        }
        .padding()
        .background(Color.ibdSurfaceBackground)
        .cornerRadius(8)
    }
}

// MARK: - Reminders View
struct MoreRemindersView: View {
    let userData: UserData?
    
    @State private var reminders: [Reminder] = []
    @State private var isLoading = false
    @State private var showingAddReminder = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading reminders...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reminders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Reminders")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Create your first reminder to stay on track with your IBD management")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingAddReminder = true }) {
                            Text("Create Reminder")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(reminders) { reminder in
                            MoreReminderRow(reminder: reminder, userData: userData) {
                                loadReminders()
                            }
                        }
                        .onDelete(perform: deleteReminder)
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddReminder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadReminders()
            }
            .sheet(isPresented: $showingAddReminder) {
                MoreAddReminderView(userData: userData) {
                    loadReminders()
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadReminders() {
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)/reminders") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        print("🔍 [MoreRemindersView] Loading reminders from: \(url)")
        print("🔍 [MoreRemindersView] Using token: \(userData?.token ?? "nil")")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            print("🔍 [MoreRemindersView] Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                            do {
                                let response = try JSONDecoder().decode(RemindersResponse.self, from: data)
                                print("🔍 [MoreRemindersView] Parsed response: \(response)")
                                self.reminders = response.reminders
                            } catch {
                                print("❌ [MoreRemindersView] Decoding error: \(error)")
                                if let decodingError = error as? DecodingError {
                                    print("❌ [MoreRemindersView] Decoding error details: \(decodingError)")
                                }
                                showError("Failed to parse reminders data")
                            }
                        }
                    } else {
                        print("❌ [MoreRemindersView] HTTP error: \(httpResponse.statusCode)")
                        showError("Failed to load reminders")
                    }
                }
            }
        }.resume()
    }
    
    private func deleteReminder(at offsets: IndexSet) {
        
        for index in offsets {
            let reminder = reminders[index]
            
            guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.id.uuidString)") else {
                showError("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
            
            NetworkManager.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        showError(error.localizedDescription)
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            loadReminders()
                        } else {
                            showError("Failed to delete reminder")
                        }
                    }
                }
            }.resume()
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Reminder Row Component
struct MoreReminderRow: View {
    let reminder: Reminder
    let userData: UserData?
    let onUpdate: () -> Void
    
    @State private var showingEditReminder = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(formatTime(reminder.time))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(formatFrequency(reminder.repeatDays))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Button(action: toggleReminder) {
                        Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash")
                            .foregroundColor(reminder.isEnabled ? .green : .gray)
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: { 
                            print("🔍 [MoreReminderRow] Edit button tapped for reminder: \(reminder.title)")
                            showingEditReminder = true 
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: deleteReminder) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Notes field not available in new Reminder model
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditReminder) {
            EditReminderView(reminder: reminder, token: userData?.token ?? "", onSave: {
                onUpdate()
            })
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func toggleReminder() {
        print("🔍 [MoreReminderRow] Toggle reminder called for ID: \(reminder.id.uuidString)")
        guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.id.uuidString)/toggle") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        onUpdate()
                    } else {
                        showError("Failed to toggle reminder")
                    }
                }
            }
        }.resume()
    }
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    private func formatFrequency(_ repeatDays: [Weekday]) -> String {
        if repeatDays.isEmpty {
            return "Once"
        } else if repeatDays.count == 7 {
            return "Daily"
        } else {
            let dayNames = repeatDays.map { $0.displayName }.joined(separator: ", ")
            return "Weekly (\(dayNames))"
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
    
    private func deleteReminder() {
        print("🔍 [MoreReminderRow] Delete reminder called for ID: \(reminder.id.uuidString)")
        guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.id.uuidString)") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        onUpdate()
                    } else {
                        showError("Failed to delete reminder")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Add Reminder View
struct MoreAddReminderView: View {
    let userData: UserData?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var reminderTime = Date()
    @State private var frequency = "daily"
    @State private var selectedDays: Set<Int> = []
    @State private var notificationMethod = "email"
    @State private var isLoading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time & Frequency") {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                        Text("Once").tag("once")
                    }
                    
                    if frequency == "weekly" {
                        ForEach(1...7, id: \.self) { day in
                            let dayName = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][day - 1]
                            Toggle(dayName, isOn: Binding(
                                get: { selectedDays.contains(day) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDays.insert(day)
                                    } else {
                                        selectedDays.remove(day)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section("Notification Method") {
                    Picker("Method", selection: $notificationMethod) {
                        Text("Email").tag("email")
                        Text("Phone").tag("phone")
                        Text("Both").tag("both")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveReminder() {
        
        // Validate weekly frequency
        if frequency == "weekly" && selectedDays.isEmpty {
            showError("Please select at least one day for weekly reminders")
            return
        }
        
        isLoading = true
        
        // Convert time to ISO8601 format for server
        let isoFormatter = ISO8601DateFormatter()
        let timeDate = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: reminderTime), minute: Calendar.current.component(.minute, from: reminderTime), second: 0, of: Date()) ?? Date()
        let isoTimeString = isoFormatter.string(from: timeDate)
        
        // Convert selected days to weekday strings
        let weekdayStrings = selectedDays.map { day in
            let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            return weekdays[day - 1]
        }
        
        let requestData: [String: Any] = [
            "title": title,
            "type": "medication", // Default type, could be made configurable
            "time": isoTimeString,
            "isEnabled": true,
            "repeatDays": weekdayStrings
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/reminders") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData?.token ?? "")", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            showError("Failed to prepare request data")
            isLoading = false
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        onSave()
                        dismiss()
                    } else {
                        showError("Failed to create reminder")
                    }
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Edit Reminder View
struct EditReminderView: View {
    let reminder: Reminder
    let token: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var notes: String
    @State private var reminderTime: Date
    @State private var frequency: String
    @State private var selectedDays: Set<Int>
    @State private var notificationMethod: String
    @State private var isLoading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    init(reminder: Reminder, token: String, onSave: @escaping () -> Void) {
        self.reminder = reminder
        self.token = token
        self.onSave = onSave
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let date = timeFormatter.string(from: reminder.time)
        let parsedDate = timeFormatter.date(from: date) ?? Date()
        
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: "") // New model doesn't have notes field
        _reminderTime = State(initialValue: parsedDate)
        _frequency = State(initialValue: "daily") // Default frequency
        _selectedDays = State(initialValue: Set(reminder.repeatDays.map { $0.rawValue.hashValue }))
        _notificationMethod = State(initialValue: "push") // Default notification method
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time & Frequency") {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                        Text("Once").tag("once")
                    }
                    
                    if frequency == "weekly" {
                        ForEach(1...7, id: \.self) { day in
                            let dayName = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][day - 1]
                            Toggle(dayName, isOn: Binding(
                                get: { selectedDays.contains(day) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDays.insert(day)
                                    } else {
                                        selectedDays.remove(day)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section("Notification Method") {
                    Picker("Method", selection: $notificationMethod) {
                        Text("Email").tag("email")
                        Text("Phone").tag("phone")
                        Text("Both").tag("both")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveReminder() {
        
        // Validate weekly frequency
        if frequency == "weekly" && selectedDays.isEmpty {
            showError("Please select at least one day for weekly reminders")
            return
        }
        
        isLoading = true
        
        // Convert time to ISO8601 format for server
        let isoFormatter = ISO8601DateFormatter()
        let timeDate = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: reminderTime), minute: Calendar.current.component(.minute, from: reminderTime), second: 0, of: Date()) ?? Date()
        let isoTimeString = isoFormatter.string(from: timeDate)
        
        // Convert selected days to weekday strings
        let weekdayStrings = selectedDays.map { day in
            let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            return weekdays[day - 1]
        }
        
        let requestData: [String: Any] = [
            "title": title,
            "type": "medication", // Default type, could be made configurable
            "time": isoTimeString,
            "isEnabled": true,
            "repeatDays": weekdayStrings
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.id.uuidString)") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        print("🔍 [EditReminderView] Updating reminder with ID: \(reminder.id.uuidString)")
        print("🔍 [EditReminderView] URL: \(url)")
        print("🔍 [EditReminderView] Request data: \(requestData)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            showError("Failed to prepare request data")
            isLoading = false
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ [EditReminderView] Network error: \(error)")
                    showError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔍 [EditReminderView] HTTP status: \(httpResponse.statusCode)")
                    if let data = data {
                        print("🔍 [EditReminderView] Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    }
                    
                    if httpResponse.statusCode == 200 {
                        onSave()
                        dismiss()
                    } else {
                        showError("Failed to update reminder")
                    }
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Data Models
// Note: Using Reminder and RemindersResponse from ReminderTypes.swift

// MARK: - Feedback View
struct FeedbackView: View {
    let userData: UserData?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Feedback form data
    @State private var nutritionFeaturesRating = 3
    @State private var nutritionHelpfulManagingSymptoms = true
    @State private var nutritionHelpfulManagingSymptomsNotes = ""
    @State private var flareupMonitoringHelpful = true
    @State private var flareupMonitoringHelpfulNotes = ""
    @State private var appRecommendations = ""
    @State private var overallRating = 3
    @State private var overallRatingNotes = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.ibdPrimary)
                    
                    Text("Share Your Feedback")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Help us improve IBDPal by sharing your experience")
                        .font(.title3)
                        .foregroundColor(.ibdSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // Nutrition Features Rating
                VStack(alignment: .leading, spacing: 16) {
                    Text("1. Nutrition Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("How would you rate the nutrition tracking features provided by the app?")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                    
                    HStack {
                        Text("Poor")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Spacer()
                        
                        ForEach(1...5, id: \.self) { rating in
                            Button(action: {
                                nutritionFeaturesRating = rating
                            }) {
                                Image(systemName: rating <= nutritionFeaturesRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(rating <= nutritionFeaturesRating ? .yellow : .gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Excellent")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                }
                
                // Nutrition Helpful for Managing Symptoms
                VStack(alignment: .leading, spacing: 16) {
                    Text("2. Symptom Management")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Were the nutrition features helpful in managing your IBD symptoms?")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            nutritionHelpfulManagingSymptoms = true
                        }) {
                            HStack {
                                Image(systemName: nutritionHelpfulManagingSymptoms ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(nutritionHelpfulManagingSymptoms ? .green : .gray)
                                Text("Yes")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(nutritionHelpfulManagingSymptoms ? .green : .ibdSecondaryText)
                        }
                        
                        Button(action: {
                            nutritionHelpfulManagingSymptoms = false
                        }) {
                            HStack {
                                Image(systemName: !nutritionHelpfulManagingSymptoms ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(!nutritionHelpfulManagingSymptoms ? .red : .gray)
                                Text("No")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(!nutritionHelpfulManagingSymptoms ? .red : .ibdSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                    
                    if nutritionHelpfulManagingSymptoms {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How did it help? (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.ibdPrimaryText)
                            
                            TextField("Share your experience...", text: $nutritionHelpfulManagingSymptomsNotes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                }
                
                // Flareup Monitoring
                VStack(alignment: .leading, spacing: 16) {
                    Text("3. Flareup Monitoring")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("Was the app helpful in monitoring and predicting flareups?")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            flareupMonitoringHelpful = true
                        }) {
                            HStack {
                                Image(systemName: flareupMonitoringHelpful ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(flareupMonitoringHelpful ? .green : .gray)
                                Text("Yes")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(flareupMonitoringHelpful ? .green : .ibdSecondaryText)
                        }
                        
                        Button(action: {
                            flareupMonitoringHelpful = false
                        }) {
                            HStack {
                                Image(systemName: !flareupMonitoringHelpful ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(!flareupMonitoringHelpful ? .red : .gray)
                                Text("No")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(!flareupMonitoringHelpful ? .red : .ibdSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                    
                    if flareupMonitoringHelpful {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How did it help? (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.ibdPrimaryText)
                            
                            TextField("Share your experience...", text: $flareupMonitoringHelpfulNotes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                }
                
                // App Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    Text("4. Recommendations")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("What recommendations do you have to help improve the app?")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                    
                    TextField("Share your suggestions...", text: $appRecommendations, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .padding()
                        .background(Color.ibdSurfaceBackground)
                        .cornerRadius(12)
                }
                
                // Overall Rating
                VStack(alignment: .leading, spacing: 16) {
                    Text("5. Overall Rating")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.ibdPrimaryText)
                    
                    Text("How would you rate your overall experience with IBDPal?")
                        .font(.body)
                        .foregroundColor(.ibdSecondaryText)
                    
                    HStack {
                        Text("Poor")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                        
                        Spacer()
                        
                        ForEach(1...5, id: \.self) { rating in
                            Button(action: {
                                overallRating = rating
                            }) {
                                Image(systemName: rating <= overallRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(rating <= overallRating ? .yellow : .gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Excellent")
                            .font(.caption)
                            .foregroundColor(.ibdSecondaryText)
                    }
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional comments (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.ibdPrimaryText)
                        
                        TextField("Share your overall experience...", text: $overallRatingNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                
                // Submit Button
                Button(action: submitFeedback) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isLoading ? "Submitting..." : "Submit Feedback")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ibdPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.top)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.ibdBackground)
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Feedback Submitted!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your feedback! Your input helps us improve IBDPal for everyone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitFeedback() {
        guard let userData = userData else {
            errorMessage = "User data not available"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        var feedbackData: [String: Any] = [
            "nutrition_features_rating": nutritionFeaturesRating,
            "nutrition_helpful_managing_symptoms": nutritionHelpfulManagingSymptoms,
            "flareup_monitoring_helpful": flareupMonitoringHelpful,
            "overall_rating": overallRating
        ]
        
        if !nutritionHelpfulManagingSymptomsNotes.isEmpty {
            feedbackData["nutrition_helpful_managing_symptoms_notes"] = nutritionHelpfulManagingSymptomsNotes
        }
        
        if !flareupMonitoringHelpfulNotes.isEmpty {
            feedbackData["flareup_monitoring_helpful_notes"] = flareupMonitoringHelpfulNotes
        }
        
        if !appRecommendations.isEmpty {
            feedbackData["app_recommendations"] = appRecommendations
        }
        
        if !overallRatingNotes.isEmpty {
            feedbackData["overall_rating_notes"] = overallRatingNotes
        }
        
        guard let url = URL(string: "\(apiBaseURL)/feedback") else {
            errorMessage = "Invalid URL"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: feedbackData)
        } catch {
            errorMessage = "Failed to prepare request data"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        showingSuccessAlert = true
                    } else {
                        if let data = data,
                           let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["error"] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = "Failed to submit feedback"
                        }
                        showingErrorAlert = true
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    MoreView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"), onSignOut: {
        print("Sign out called from preview")
    })
} 
