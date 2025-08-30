import SwiftUI

struct MoreView: View {
    let userData: UserData?
    let onSignOut: () -> Void
    
    @State private var showingLogoutAlert = false
    @State private var isSigningOut = false
    
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
                }
                
                // Settings Section
                Section("Settings") {
                    NavigationLink(destination: ProfileView(userData: userData)) {
                        MoreRow(icon: "person.fill", title: "Profile", subtitle: "Edit your profile")
                    }
                    
                    NavigationLink(destination: RemindersView(userData: userData)) {
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
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        MoreRow(icon: "envelope.fill", title: "Contact Support", subtitle: "Get in touch with us")
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
        guard let userData = userData else { return }
        
        // Parse name into first and last name
        let nameComponents = userData.name?.components(separatedBy: " ") ?? []
        firstName = nameComponents.first ?? ""
        lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        email = userData.email ?? ""
        phoneNumber = userData.phoneNumber ?? ""
    }
    
    private func updateProfile() {
        guard let userData = userData else { return }
        
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
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
        guard let userData = userData else { return }
        
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
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
            VStack(alignment: .leading, spacing: 25) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IBDPal")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            Text("Your IBD Management Companion")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Mission Statement
                VStack(alignment: .leading, spacing: 12) {
                    Text("Our Mission")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("IBDPal is dedicated to empowering individuals with Inflammatory Bowel Disease (IBD) to take control of their health journey. We believe that comprehensive monitoring, personalized insights, and informed decision-making are the keys to achieving and maintaining remission.")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // What We Do
                VStack(alignment: .leading, spacing: 12) {
                    Text("What We Do")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(
                            icon: "calendar.badge.plus",
                            title: "Daily Monitoring",
                            description: "Comprehensive tracking of meals, symptoms, medications, and lifestyle factors"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Health Analytics",
                            description: "Advanced analytics in the Trends tab to identify patterns and correlations in your health data"
                        )
                        
                        FeatureRow(
                            icon: "magnifyingglass",
                            title: "Nutrition Guidance",
                            description: "Intelligent food database in the Connect tab with FODMAP filtering and nutrition analysis"
                        )
                        
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI-Powered Insights",
                            description: "Machine learning algorithms to predict flare risks and provide personalized recommendations"
                        )
                        
                        FeatureRow(
                            icon: "lock.shield",
                            title: "Privacy First",
                            description: "Enterprise-grade security and privacy protection for your sensitive health data"
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Our Approach
                VStack(alignment: .leading, spacing: 12) {
                    Text("Our Approach")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("We combine cutting-edge technology with evidence-based medical knowledge to create a comprehensive IBD management platform. Our approach is rooted in the understanding that every IBD journey is unique, and personalized care is essential for success.")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("By providing you with the tools to track, analyze, and understand your health patterns, we empower you to work collaboratively with your healthcare team to achieve the best possible outcomes.")
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Contact Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get in Touch")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ContactRow(
                            icon: "envelope.fill",
                            title: "Support",
                            detail: "support@ibdpal.com"
                        )
                        
                        ContactRow(
                            icon: "globe",
                            title: "Website",
                            detail: "www.ibdpal.com"
                        )
                        
                        ContactRow(
                            icon: "phone.fill",
                            title: "Emergency",
                            detail: "Contact your healthcare provider"
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Disclaimer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medical Disclaimer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("IBDPal is designed to support your IBD management journey but is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with your healthcare provider for medical decisions and emergency situations.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                .cornerRadius(8)
            }
            .padding()
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Contact Row Component
struct ContactRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Reminders View
struct RemindersView: View {
    let userData: UserData?
    
    @State private var reminders: [UserReminder] = []
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
                            ReminderRow(reminder: reminder, userData: userData) {
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
                AddReminderView(userData: userData) {
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
        guard let userData = userData else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)/reminders") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
                            do {
                                let response = try JSONDecoder().decode(RemindersResponse.self, from: data)
                                self.reminders = response.reminders
                            } catch {
                                showError("Failed to parse reminders data")
                            }
                        }
                    } else {
                        showError("Failed to load reminders")
                    }
                }
            }
        }.resume()
    }
    
    private func deleteReminder(at offsets: IndexSet) {
        guard let userData = userData else { return }
        
        for index in offsets {
            let reminder = reminders[index]
            
            guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.reminder_id)") else {
                showError("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
            
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
struct ReminderRow: View {
    let reminder: UserReminder
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
                    
                    Text(formatTime(reminder.reminder_time))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(formatFrequency(reminder.frequency, reminder.days_of_week))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Button(action: toggleReminder) {
                        Image(systemName: reminder.is_active ? "bell.fill" : "bell.slash")
                            .foregroundColor(reminder.is_active ? .green : .gray)
                    }
                    
                    Button(action: { showingEditReminder = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let notes = reminder.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditReminder) {
            EditReminderView(reminder: reminder) {
                onUpdate()
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func toggleReminder() {
        guard let userData = reminder.userData else { return }
        
        guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.reminder_id)/toggle") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
    
    private func formatTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let date = formatter.date(from: time) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        return time
    }
    
    private func formatFrequency(_ frequency: String, _ daysOfWeek: [Int]?) -> String {
        switch frequency {
        case "daily":
            return "Daily"
        case "weekly":
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let selectedDays = days.map { dayNames[$0 - 1] }.joined(separator: ", ")
                return "Weekly (\(selectedDays))"
            }
            return "Weekly"
        case "monthly":
            return "Monthly"
        case "once":
            return "Once"
        default:
            return frequency
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Add Reminder View
struct AddReminderView: View {
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
        guard let userData = userData else { return }
        
        // Validate weekly frequency
        if frequency == "weekly" && selectedDays.isEmpty {
            showError("Please select at least one day for weekly reminders")
            return
        }
        
        isLoading = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: reminderTime)
        
        let requestData: [String: Any] = [
            "title": title,
            "notes": notes.isEmpty ? nil : notes,
            "reminder_time": timeString,
            "frequency": frequency,
            "days_of_week": frequency == "weekly" ? Array(selectedDays).sorted() : nil,
            "notification_method": notificationMethod
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/reminders") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
    let reminder: UserReminder
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
    
    init(reminder: UserReminder, onSave: @escaping () -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let date = timeFormatter.date(from: reminder.reminder_time) ?? Date()
        
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: reminder.notes ?? "")
        _reminderTime = State(initialValue: date)
        _frequency = State(initialValue: reminder.frequency)
        _selectedDays = State(initialValue: Set(reminder.days_of_week ?? []))
        _notificationMethod = State(initialValue: reminder.notification_method)
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
        guard let userData = reminder.userData else { return }
        
        // Validate weekly frequency
        if frequency == "weekly" && selectedDays.isEmpty {
            showError("Please select at least one day for weekly reminders")
            return
        }
        
        isLoading = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: reminderTime)
        
        let requestData: [String: Any] = [
            "title": title,
            "notes": notes.isEmpty ? nil : notes,
            "reminder_time": timeString,
            "frequency": frequency,
            "days_of_week": frequency == "weekly" ? Array(selectedDays).sorted() : nil,
            "notification_method": notificationMethod
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/reminders/\(reminder.reminder_id)") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(userData.token)", forHTTPHeaderField: "Authorization")
        
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
struct UserReminder: Codable, Identifiable {
    let reminder_id: String
    let user_id: String
    let title: String
    let notes: String?
    let reminder_time: String
    let frequency: String
    let days_of_week: [Int]?
    let is_active: Bool
    let notification_method: String
    let created_at: String
    let updated_at: String
    
    var id: String { reminder_id }
    var userData: UserData? { nil } // This will be set when needed
}

struct RemindersResponse: Codable {
    let reminders: [UserReminder]
}

#Preview {
    MoreView(userData: UserData(id: "1", email: "test@example.com", name: "Test User", phoneNumber: nil, token: "token"), onSignOut: {
        print("Sign out called from preview")
    })
} 