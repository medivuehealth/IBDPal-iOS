import Foundation

// Test script for iOS network connection to Railway
class NetworkTester {
    static let railwayURL = "https://ibdpal-server-production.up.railway.app"
    
    static func testHealthCheck() {
        print("🏥 Testing Health Check...")
        
        guard let url = URL(string: "\(railwayURL)/api/health") else {
            print("❌ Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Health Check Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Health Check Status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString)")
                }
            }
        }
        
        task.resume()
    }
    
    static func testRegistration() {
        print("📝 Testing Registration...")
        
        guard let url = URL(string: "\(railwayURL)/api/auth/register") else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let testUser: [String: Any] = [
            "username": "testuser_\(Int(Date().timeIntervalSince1970))",
            "email": "test\(Int(Date().timeIntervalSince1970))@example.com",
            "password": "testpass123",
            "confirmPassword": "testpass123",
            "firstName": "Test",
            "lastName": "User",
            "agreeToTerms": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testUser)
        } catch {
            print("❌ Failed to serialize request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Registration Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Registration Status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString)")
                }
            }
        }
        
        task.resume()
    }
    
    static func testWithCustomSession() {
        print("🔒 Testing with Custom Session...")
        
        guard let url = URL(string: "\(railwayURL)/api/health") else {
            print("❌ Invalid URL")
            return
        }
        
        // Create custom session with SSL bypass
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        
        class SSLDelegate: NSObject, URLSessionDelegate {
            func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
                print("🔐 SSL Challenge received for: \(challenge.protectionSpace.host)")
                print("🔐 Accepting SSL challenge")
                completionHandler(.useCredential, nil)
            }
        }
        
        let session = URLSession(configuration: config, delegate: SSLDelegate(), delegateQueue: nil)
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Custom Session Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Custom Session Status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString)")
                }
            }
        }
        
        task.resume()
    }
}

// Usage instructions:
// 1. Copy this code to a Swift playground
// 2. Run each test function
// 3. Check the console output

print("🚀 iOS Network Test Script")
print("Run these functions in a Swift playground:")
print("NetworkTester.testHealthCheck()")
print("NetworkTester.testRegistration()")
print("NetworkTester.testWithCustomSession()") 