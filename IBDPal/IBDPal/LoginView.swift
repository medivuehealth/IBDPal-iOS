import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var userData: UserData?
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = "Login Failed"
    @State private var showRegistration = false
    @State private var keyboardHeight: CGFloat = 0
    
    // Updated API URL to match your backend
    private let apiBaseURL = AppConfig.apiBaseURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Welcome to IBDPal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your pediatric IBD care companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Form
                    VStack(spacing: 15) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Email Address")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .disabled(isLoading)
                            
                            if !emailError.isEmpty {
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Login Button
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isLoading ? "Signing In..." : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.6, green: 0.2, blue: 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                        
                        // Register Link
                        Button("Don't have an account? Sign Up") {
                            print("DEBUG: Sign Up button tapped")
                            showRegistration = true
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.8))
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 50 : 0)
            }
            .alert(errorTitle, isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showRegistration) {
                RegisterView(isAuthenticated: $isAuthenticated, userData: $userData)
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        emailError = ""
        passwordError = ""
        
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
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleLogin() {
        guard validateForm() else { return }
        
        isLoading = true
        
        // Log the login attempt
        NetworkLogger.shared.log("🔐 Login attempt for: \(email)", level: .info, category: .auth)
        
        guard let url = URL(string: "\(apiBaseURL)\(AppConfig.Endpoints.login)") else {
            NetworkLogger.shared.log("❌ Invalid URL: \(apiBaseURL)/auth/login", level: .error, category: .auth)
            showError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Increase timeout to 30 seconds
        
        let loginData = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            showError("Failed to prepare request")
            return
        }
        
        NetworkManager.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                // Log the network request
                NetworkLogger.shared.logNetworkRequest(request, response: response, data: data, error: error)
                
                if let error = error {
                    NetworkLogger.shared.log("❌ Login failed: \(error.localizedDescription)", level: .error, category: .auth)
                    showError("Unable to connect to the server. Please check your internet connection and try again.")
                    return
                }
                
                guard let data = data else {
                    NetworkLogger.shared.log("❌ No data received from server", level: .error, category: .auth)
                    showError("No data received from server")
                    return
                }
                
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let httpResponse = response as? HTTPURLResponse {
                            NetworkLogger.shared.log("📥 HTTP Status: \(httpResponse.statusCode)", level: .info, category: .auth)
                            print("Full JSON response: \(json)")
                            
                            if httpResponse.statusCode == 200 {
                                // Success - parse the actual server response format
                                NetworkLogger.shared.log("✅ Login successful", level: .info, category: .auth)
                                
                                // Parse the actual server response format
                                if let token = json["token"] as? String,
                                   let user = json["user"] as? [String: Any],
                                   let username = user["username"] as? String,  // Server returns username
                                   let userEmail = user["email"] as? String {
                                    
                                    let userData = UserData(
                                        id: username,  // Use username as ID
                                        email: userEmail,
                                        name: "\(user["firstName"] as? String ?? "") \(user["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces),
                                        phoneNumber: nil,
                                        token: token
                                    )
                                    
                                    self.userData = userData
                                    self.isAuthenticated = true
                                    NetworkLogger.shared.log("✅ User authenticated: \(userEmail)", level: .info, category: .auth)
                                } else {
                                    print("Expected fields not found in response")
                                    print("Available keys: \(json.keys)")
                                    print("Token field: \(json["token"] ?? "NOT FOUND")")
                                    print("User field: \(json["user"] ?? "NOT FOUND")")
                                    if let user = json["user"] as? [String: Any] {
                                        print("User keys: \(user.keys)")
                                        print("User username: \(user["username"] ?? "NOT FOUND")")
                                        print("User email: \(user["email"] ?? "NOT FOUND")")
                                    }
                                    NetworkLogger.shared.log("❌ Response format not recognized", level: .error, category: .auth)
                                    showError("Server response format not recognized. Please try again.")
                                }
                            } else {
                                // Error
                                let errorMessage = json["message"] as? String ?? json["error"] as? String ?? "Invalid email or password"
                                NetworkLogger.shared.log("❌ Login failed: \(errorMessage)", level: .error, category: .auth)
                                showError(errorMessage)
                            }
                        }
                    }
                } catch {
                    NetworkLogger.shared.log("❌ JSON parsing error: \(error)", level: .error, category: .auth)
                    showError("Failed to parse server response")
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        errorTitle = "Login Failed"
        showErrorAlert = true
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false), userData: .constant(nil))
} 