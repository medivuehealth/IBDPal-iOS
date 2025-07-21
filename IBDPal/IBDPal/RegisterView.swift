import SwiftUI

struct RegisterView: View {
    @Binding var isAuthenticated: Bool
    @Binding var userData: UserData?
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var nameError = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = "Registration Failed"
    
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
            nameField
            emailField
            passwordField
            confirmPasswordField
            registerButton
            loginLink
        }
        .padding(.horizontal, 20)
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Full Name")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            TextField("Enter your full name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .disabled(isLoading)
            
            if !nameError.isEmpty {
                Text(nameError)
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
    
    private var loginLink: some View {
        Button("Already have an account? Sign In") {
            dismiss()
        }
        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
        .font(.subheadline)
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        nameError = ""
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Name is required"
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
        
        // Split name into firstName and lastName
        let nameComponents = name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        let registerData: [String: Any] = [
            "username": email.trimmingCharacters(in: .whitespacesAndNewlines), // Use email as username
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "confirmPassword": confirmPassword,
            "firstName": firstName,
            "lastName": lastName,
            "agreeToTerms": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registerData)
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
                                // Success - try different response formats
                                if let token = json["token"] as? String,
                                   let user = json["user"] as? [String: Any],
                                   let username = user["username"] as? String,
                                   let userEmail = user["email"] as? String {
                                    
                                    let userData = UserData(
                                        id: username,
                                        email: userEmail,
                                        name: user["name"] as? String,
                                        token: token
                                    )
                                    
                                    self.userData = userData
                                    self.isAuthenticated = true
                                } else if let token = json["token"] as? String,
                                          let username = json["username"] as? String,
                                          let userEmail = json["email"] as? String {
                                    // Alternative format without nested user object
                                    let userData = UserData(
                                        id: username,
                                        email: userEmail,
                                        name: json["name"] as? String,
                                        token: token
                                    )
                                    
                                    self.userData = userData
                                    self.isAuthenticated = true
                                } else {
                                    print("Expected fields not found in response")
                                    print("Available keys: \(json.keys)")
                                    showError("Server response format not recognized. Please try again.")
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
}

#Preview {
    RegisterView(isAuthenticated: .constant(false), userData: .constant(nil))
} 