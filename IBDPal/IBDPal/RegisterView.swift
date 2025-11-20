import SwiftUI
import Combine

struct RegisterView: View {
    @Binding var isAuthenticated: Bool
    @Binding var userData: UserData?
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var emailError = ""
    @State private var phoneNumberError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = "Registration Failed"
    @State private var agreedToTerms = false
    @State private var showTermsAndConditions = false
    @State private var showPrivacyPolicy = false
    @State private var showEmailVerification = false
    @State private var showPhoneVerification = false
    @State private var pendingUserData: [String: Any] = [:]
    @State private var verificationEmail = ""
    @State private var verificationPhoneNumber = ""
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    formView
                }
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
            .alert(errorTitle, isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            Text("Join IBDPal to start your IBD care journey")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
        }
        .padding(.top, 30)
    }
    
    private var formView: some View {
        VStack(spacing: 15) {
            firstNameField
            lastNameField
            emailField
            phoneNumberField
            passwordField
            confirmPasswordField
            termsAndConditionsSection
            registerButton
            loginLink
        }
        .padding(.horizontal, 20)
    }
    
    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("First Name")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            TextField("Enter your first name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .disabled(isLoading)
            
            if !firstNameError.isEmpty {
                Text(firstNameError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var lastNameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Last Name")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            TextField("Enter your last name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .disabled(isLoading)
            
            if !lastNameError.isEmpty {
                Text(lastNameError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Email Address")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(isLoading)
            
            if !emailError.isEmpty {
                Text(emailError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var phoneNumberField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Phone Number")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            TextField("Enter your phone number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(isLoading)
            
            if !phoneNumberError.isEmpty {
                Text(phoneNumberError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Password")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            HStack {
                if showPassword {
                    TextField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .disabled(isLoading)
            
            if !passwordError.isEmpty {
                Text(passwordError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Confirm Password")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            HStack {
                if showConfirmPassword {
                    TextField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    showConfirmPassword.toggle()
                }) {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .disabled(isLoading)
            
            if !confirmPasswordError.isEmpty {
                Text(confirmPasswordError)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var registerButton: some View {
        Button(action: handleRegister) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Creating Account..." : "Create Account")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.6, green: 0.2, blue: 0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
    
    private var termsAndConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: {
                    agreedToTerms.toggle()
                }) {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? Color(red: 0.6, green: 0.2, blue: 0.8) : .gray)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree to the ")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    + Text("Terms and Conditions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                    + Text(" and ")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    + Text("Privacy Policy")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                    + Text(" *")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 16) {
                Button("Terms & Conditions") {
                    showTermsAndConditions = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                
                Button("Privacy Policy") {
                    showPrivacyPolicy = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
            }
        }
        .sheet(isPresented: $showTermsAndConditions) {
            TermsAndConditionsView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showEmailVerification) {
            EmailVerificationView(
                email: verificationEmail,
                pendingUserData: pendingUserData,
                onVerificationSuccess: { userData in
                    self.userData = userData
                    self.isAuthenticated = true
                    self.showEmailVerification = false
                },
                onVerificationFailure: { error in
                    self.showError("Verification Failed", error)
                }
            )
        }
        .sheet(isPresented: $showPhoneVerification) {
            PhoneVerificationView(
                phoneNumber: verificationPhoneNumber,
                pendingUserData: pendingUserData,
                onVerificationSuccess: { userData in
                    self.userData = userData
                    self.isAuthenticated = true
                    self.showPhoneVerification = false
                },
                onVerificationFailure: { error in
                    self.showError("Verification Failed", error)
                }
            )
        }
    }
    
    private var loginLink: some View {
        Button("Already have an account? Sign In") {
            dismiss()
        }
        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
        .font(.subheadline)
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        firstNameError = ""
        lastNameError = ""
        emailError = ""
        phoneNumberError = ""
        passwordError = ""
        confirmPasswordError = ""
        
        // Terms and Conditions validation
        if !agreedToTerms {
            showError("Terms and Conditions", "You must agree to the Terms and Conditions and Privacy Policy to continue.")
            return false
        }
        
        // First Name validation
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstNameError = "First name is required"
            isValid = false
        }
        
        // Last Name validation
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastNameError = "Last name is required"
            isValid = false
        }
        
        // Email validation
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required"
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
            isValid = false
        }
        
        // Phone Number validation
        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            phoneNumberError = "Phone number is required"
            isValid = false
        } else if !isValidPhoneNumber(phoneNumber) {
            phoneNumberError = "Please enter a valid phone number"
            isValid = false
        }
        
        // Password validation
        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            isValid = false
        }
        
        // Confirm password validation
        if confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            confirmPasswordError = "Please confirm your password"
            isValid = false
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // Basic phone number validation - accepts various formats
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleaned.count >= 10 && cleaned.count <= 20
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Clean and normalize the email for validation
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = cleanEmail.lowercased()
        
        let emailRegex = "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: normalizedEmail)
    }
    
    private func handleRegister() {
        guard validateForm() else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)\(AppConfig.Endpoints.register)") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registerData: [String: Any] = [
            "username": email.trimmingCharacters(in: .whitespacesAndNewlines), // Use email as username
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "phoneNumber": phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "confirmPassword": confirmPassword,
            "firstName": firstName,
            "lastName": lastName,
            "agreeToTerms": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registerData)
            
            // Debug: Print the data being sent
            print("🔍 [RegisterView] Sending registration data:")
            print("   firstName: '\(firstName)'")
            print("   lastName: '\(lastName)'")
            print("   email: '\(email)'")
            print("   Full request data: \(registerData)")
            
        } catch {
            showError("Failed to prepare request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError("Unable to connect to the server. Please check your internet connection and try again.")
                    print("Network error: \(error)")
                    return
                }
                
                guard let data = data else {
                    showError("No data received from server")
                    return
                }
                
                // Print response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server response: \(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            print("HTTP Status: \(httpResponse.statusCode)")
                            print("Full JSON response: \(json)")
                            
                            if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                                // Check if verification is required (now using SMS/phone)
                                if let requiresVerification = json["requiresVerification"] as? Bool, requiresVerification {
                                    // Store pending user data and show phone verification screen
                                    self.pendingUserData = registerData
                                    self.verificationPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                                    self.showPhoneVerification = true
                                    print("📱 [RegisterView] Phone verification required for: \(phoneNumber)")
                                } else {
                                    // Direct registration success - handle both registration and login response formats
                                    if let token = json["token"] as? String,
                                       let user = json["user"] as? [String: Any],
                                       let userEmail = user["email"] as? String {
                                        
                                        // Handle both username (login) and id (registration) fields
                                        let userId = user["username"] as? String ?? user["id"] as? String ?? userEmail
                                        
                                        // Combine firstName and lastName for display name
                                        let firstName = user["firstName"] as? String ?? ""
                                        let lastName = user["lastName"] as? String ?? ""
                                        let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                        
                                        let userData = UserData(
                                            id: userId,
                                            email: userEmail,
                                            name: displayName,
                                            phoneNumber: nil,
                                            token: token
                                        )
                                        
                                        self.userData = userData
                                        self.isAuthenticated = true
                                        print("✅ [RegisterView] Registration successful! User ID: \(userId)")
                                    } else {
                                        print("Expected fields not found in response")
                                        print("Available keys: \(json.keys)")
                                        if let user = json["user"] as? [String: Any] {
                                            print("User object keys: \(user.keys)")
                                        }
                                        showError("Server response format not recognized. Please try again.")
                                    }
                                }
                            } else {
                                // Error
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Registration failed"
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    showError("Failed to parse server response")
                    print("JSON parsing error: \(error)")
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        errorTitle = "Registration Failed"
        showErrorAlert = true
    }
    
    private func showError(_ title: String, _ message: String) {
        errorMessage = message
        errorTitle = title
        showErrorAlert = true
    }
}

// MARK: - Terms and Conditions View
struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms and Conditions")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Important Legal Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IMPORTANT LEGAL DISCLAIMER")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("EDUCATIONAL PURPOSE ONLY - NOT MEDICAL ADVICE")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("IBDPal is designed and intended for EDUCATIONAL PURPOSES ONLY. This application is NOT a substitute for professional medical advice, diagnosis, or treatment. The information provided within this application is for general educational and informational purposes only and should not be construed as medical advice.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    
                    // No Medical Advice
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. NO MEDICAL ADVICE")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("The content, features, and functionality of IBDPal are provided for educational and informational purposes only. This application does not provide medical advice, diagnosis, or treatment recommendations. Users should NOT rely on this application for medical decision-making.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Professional Medical Consultation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. PROFESSIONAL MEDICAL CONSULTATION REQUIRED")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Users are strongly advised to consult with qualified healthcare professionals, including but not limited to gastroenterologists, registered dietitians, and primary care physicians, for all medical decisions, treatment plans, and dietary recommendations. This application should not replace professional medical consultation.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Limitation of Liability
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3. LIMITATION OF LIABILITY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, THE DEVELOPERS, CREATORS, AND DISTRIBUTORS OF IBDPAL SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES, RESULTING FROM THE USE OR INABILITY TO USE THIS APPLICATION.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // No Warranty
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4. NO WARRANTY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("THIS APPLICATION IS PROVIDED 'AS IS' AND 'AS AVAILABLE' WITHOUT ANY WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. THE DEVELOPERS MAKE NO WARRANTIES REGARDING THE ACCURACY, RELIABILITY, OR COMPLETENESS OF ANY INFORMATION PROVIDED THROUGH THIS APPLICATION.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Indemnification
                    VStack(alignment: .leading, spacing: 8) {
                        Text("5. INDEMNIFICATION")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("By using this application, you agree to indemnify, defend, and hold harmless the developers, creators, and distributors of IBDPal from and against any and all claims, damages, losses, liabilities, costs, and expenses (including reasonable attorneys' fees) arising from or relating to your use of this application or any violation of these terms.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Legal Proceedings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("6. LEGAL PROCEEDINGS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("By using this application, you acknowledge and agree that the developers, creators, and distributors of IBDPal shall not be subject to legal proceedings, lawsuits, or claims arising from the use of this application. This application is provided purely for educational purposes and should not be used as a basis for medical decisions or legal actions.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // User Responsibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7. USER RESPONSIBILITY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Users are solely responsible for their own health decisions and actions. The use of this application does not create a doctor-patient relationship or any other professional relationship. Users should always consult with qualified healthcare professionals for medical advice and treatment.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Emergency Situations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("8. EMERGENCY SITUATIONS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("In case of medical emergencies, users should immediately contact emergency services (911 in the United States) or seek immediate medical attention. This application is not designed to handle emergency situations and should not be used as a substitute for emergency medical care.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Acceptance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("9. ACCEPTANCE OF TERMS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("By using IBDPal, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, you should not use this application.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("10. CONTACT INFORMATION")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("For questions regarding these Terms and Conditions, please contact the development team through the application's support channels.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
                    
                    // Data Retention
                    VStack(alignment: .leading, spacing: 8) {
                        Text("6. DATA RETENTION")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("We retain your personal information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When we no longer need your information, we will securely delete or anonymize it.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Your Rights
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7. YOUR RIGHTS AND CHOICES")
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
                        Text("8. HEALTH DATA PROTECTION")
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
                    
                    // Cookies and Tracking
                    VStack(alignment: .leading, spacing: 8) {
                        Text("9. COOKIES AND TRACKING TECHNOLOGIES")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Our application may use cookies and similar tracking technologies to enhance your experience. You can control cookie settings through your device preferences. We do not use tracking technologies for advertising purposes.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Children's Privacy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("10. CHILDREN'S PRIVACY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Our application is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // International Transfers
                    VStack(alignment: .leading, spacing: 8) {
                        Text("11. INTERNATIONAL DATA TRANSFERS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("Your information may be transferred to and processed in countries other than your own. We ensure that such transfers comply with applicable data protection laws and implement appropriate safeguards to protect your data.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Policy Updates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("12. CHANGES TO THIS PRIVACY POLICY")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy in the application and updating the 'Last updated' date. Your continued use of the application after such changes constitutes acceptance of the updated policy.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("13. CONTACT US")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("If you have any questions about this Privacy Policy or our data practices, please contact us through the application's support channels or at our designated privacy contact.")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    // Legal Basis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("14. LEGAL BASIS FOR PROCESSING")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        Text("We process your personal data based on the following legal grounds:")
                            .font(.body)
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Consent: When you explicitly agree to data processing")
                            Text("• Contract: To provide the services you requested")
                            Text("• Legitimate Interest: To improve our services and security")
                            Text("• Legal Obligation: To comply with applicable laws")
                        }
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                }
                .padding()
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
        }
    }
}

// MARK: - Email Verification View
struct EmailVerificationView: View {
    let email: String
    let pendingUserData: [String: Any]
    let onVerificationSuccess: (UserData) -> Void
    let onVerificationFailure: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var countdownSeconds = 60
    @State private var canResend = false
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                    
                    Text("Verify Your Email")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("We've sent a verification code to")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    
                    Text(email)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Verification Code Input
                VStack(spacing: 16) {
                    Text("Enter the 6-digit verification code")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            VerificationCodeDigitField(
                                index: index,
                                code: $verificationCode
                            )
                            .onChange(of: verificationCode) { newCode in
                                // Auto-advance to next field when a digit is entered
                                if newCode.count > index && index < 5 {
                                    // Focus will automatically move to next field
                                }
                            }
                        }
                    }
                }
                
                // Verify Button
                Button(action: handleVerification) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Verifying..." : "Verify Email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.6, green: 0.2, blue: 0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || verificationCode.count != 6)
                
                // Resend Code Section
                VStack(spacing: 12) {
                    if canResend {
                        Button(action: handleResendCode) {
                            HStack {
                                if isResending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.6, green: 0.2, blue: 0.8)))
                                        .scaleEffect(0.8)
                                }
                                Text(isResending ? "Sending..." : "Resend Code")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                        .disabled(isResending)
                    } else {
                        Text("Resend code in \(countdownSeconds) seconds")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 50)
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
            .alert("Verification Failed", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                startCountdown()
            }
        }
    }
    
    private func handleVerification() {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)/auth/verify-email") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let verificationData: [String: Any] = [
            "email": email,
            "verificationCode": verificationCode
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: verificationData)
        } catch {
            showError("Failed to prepare verification request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    showError("No data received from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                // Verification successful
                                if let token = json["token"] as? String,
                                   let user = json["user"] as? [String: Any],
                                   let userEmail = user["email"] as? String {
                                    
                                    let userId = user["username"] as? String ?? user["id"] as? String ?? userEmail
                                    let firstName = user["firstName"] as? String ?? ""
                                    let lastName = user["lastName"] as? String ?? ""
                                    let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                    
                                    let userData = UserData(
                                        id: userId,
                                        email: userEmail,
                                        name: displayName,
                                        phoneNumber: nil,
                                        token: token
                                    )
                                    
                                    onVerificationSuccess(userData)
                                } else {
                                    showError("Invalid response format from server")
                                }
                            } else {
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Verification failed"
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    showError("Failed to parse server response")
                }
            }
        }.resume()
    }
    
    private func handleResendCode() {
        isResending = true
        
        guard let url = URL(string: "\(apiBaseURL)/auth/resend-verification") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let resendData: [String: Any] = [
            "email": email,
            "userData": pendingUserData
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: resendData)
        } catch {
            showError("Failed to prepare resend request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isResending = false
                
                if let error = error {
                    showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    showError("No data received from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                // Resend successful
                                startCountdown()
                            } else {
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Failed to resend code"
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    showError("Failed to parse server response")
                }
            }
        }.resume()
    }
    
    private func startCountdown() {
        canResend = false
        countdownSeconds = 60
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

// MARK: - Verification Code Digit Field
struct VerificationCodeDigitField: View {
    let index: Int
    @Binding var code: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: Binding(
            get: {
                if index < code.count {
                    return String(code[code.index(code.startIndex, offsetBy: index)])
                }
                return ""
            },
            set: { newValue in
                // Only allow single digit
                if newValue.count <= 1 {
                    if newValue.isEmpty {
                        // Handle backspace
                        if code.count > index {
                            code.remove(at: code.index(code.startIndex, offsetBy: index))
                        }
                        // Move to previous field on backspace
                        if index > 0 && newValue.isEmpty {
                            // Focus will be handled by parent view
                        }
                    } else {
                        // Handle digit input
                        let digit = newValue.first!
                        if digit.isNumber {
                            if index < code.count {
                                code.remove(at: code.index(code.startIndex, offsetBy: index))
                                code.insert(digit, at: code.index(code.startIndex, offsetBy: index))
                            } else {
                                code.append(digit)
                            }
                            
                            // Auto-advance to next field if not the last field
                            if index < 5 && code.count > index + 1 {
                                // Focus will be handled by parent view
                            }
                        }
                    }
                }
            }
        ))
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .frame(width: 45, height: 55)
        .multilineTextAlignment(.center)
        .font(.title2)
        .fontWeight(.bold)
        .keyboardType(.numberPad)
        .focused($isFocused)
        .onReceive(Just(code)) { _ in
            if code.count > 6 {
                code = String(code.prefix(6))
            }
        }
        .onChange(of: code) { newCode in
            // Auto-advance logic
            if newCode.count > index && index < 5 {
                // Move focus to next field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This will be handled by the parent view
                }
            }
        }
    }
}

// MARK: - Phone Verification View
struct PhoneVerificationView: View {
    let phoneNumber: String
    let pendingUserData: [String: Any]
    let onVerificationSuccess: (UserData) -> Void
    let onVerificationFailure: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var countdownSeconds = 60
    @State private var canResend = false
    
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                    
                    Text("Verify Your Phone")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    Text("We've sent a verification code to")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    
                    Text(phoneNumber)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                }
                
                // Verification Code Input
                VStack(spacing: 16) {
                    Text("Enter the 6-digit verification code")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            VerificationCodeDigitField(
                                index: index,
                                code: $verificationCode
                            )
                        }
                    }
                }
                
                // Verify Button
                Button(action: handleVerification) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Verifying..." : "Verify Phone")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.6, green: 0.2, blue: 0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || verificationCode.count != 6)
                
                // Resend Code Section
                VStack(spacing: 12) {
                    if canResend {
                        Button(action: handleResendCode) {
                            HStack {
                                if isResending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.6, green: 0.2, blue: 0.8)))
                                        .scaleEffect(0.8)
                                }
                                Text(isResending ? "Sending..." : "Resend Code")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                        .disabled(isResending)
                    } else {
                        Text("Resend code in \(countdownSeconds) seconds")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 50)
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .navigationTitle("Phone Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                }
            }
            .alert("Verification Failed", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                startCountdown()
            }
        }
    }
    
    private func handleVerification() {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(apiBaseURL)/auth/verify-phone") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let verificationData: [String: Any] = [
            "phoneNumber": phoneNumber,
            "verificationCode": verificationCode
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: verificationData)
        } catch {
            showError("Failed to prepare verification request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    showError("No data received from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                // Verification successful
                                if let token = json["token"] as? String,
                                   let user = json["user"] as? [String: Any],
                                   let userEmail = user["email"] as? String {
                                    
                                    let userId = user["username"] as? String ?? user["id"] as? String ?? userEmail
                                    let firstName = user["firstName"] as? String ?? ""
                                    let lastName = user["lastName"] as? String ?? ""
                                    let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                    let phoneNumber = user["phoneNumber"] as? String
                                    
                                    let userData = UserData(
                                        id: userId,
                                        email: userEmail,
                                        name: displayName,
                                        phoneNumber: phoneNumber,
                                        token: token
                                    )
                                    
                                    onVerificationSuccess(userData)
                                } else {
                                    showError("Invalid response format from server")
                                }
                            } else {
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Verification failed"
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    showError("Failed to parse server response")
                }
            }
        }.resume()
    }
    
    private func handleResendCode() {
        isResending = true
        
        guard let url = URL(string: "\(apiBaseURL)/auth/resend-verification") else {
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let resendData: [String: Any] = [
            "phoneNumber": phoneNumber
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: resendData)
        } catch {
            showError("Failed to prepare resend request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isResending = false
                
                if let error = error {
                    showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    showError("No data received from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                // Resend successful
                                startCountdown()
                            } else {
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Failed to resend code"
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    showError("Failed to parse server response")
                }
            }
        }.resume()
    }
    
    private func startCountdown() {
        canResend = false
        countdownSeconds = 60
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

#Preview {
    RegisterView(isAuthenticated: .constant(false), userData: .constant(nil))
} 