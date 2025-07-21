import SwiftUI

struct NetworkTestView: View {
    @State private var testResult = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Network Connection Test")
                .font(.title2)
                .foregroundColor(.ibdPrimary)
            
            Button("Test Server Connection") {
                testServerConnection()
            }
            .buttonStyle(.borderedProminent)
            .tint(.ibdPrimary)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if !testResult.isEmpty {
                Text(testResult)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.ibdPrimaryText)
                    .padding()
                    .background(Color.ibdSurfaceBackground)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Network Test")
    }
    
    private func testServerConnection() {
        isLoading = true
        testResult = "Testing connection to \(AppConfig.serverBaseURL)..."
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)\(AppConfig.Endpoints.health)") else {
            testResult = "❌ Invalid URL: \(AppConfig.apiBaseURL)\(AppConfig.Endpoints.health)"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    testResult = "❌ Connection Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    testResult += "\n📡 HTTP Status: \(httpResponse.statusCode)"
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        testResult += "\n📄 Response: \(responseString)"
                    }
                    
                    if httpResponse.statusCode == 200 {
                        testResult = "✅ Connection Successful!\n" + testResult
                    } else {
                        testResult = "⚠️ Server responded with status \(httpResponse.statusCode)\n" + testResult
                    }
                } else {
                    testResult = "❌ Invalid response type"
                }
            }
        }.resume()
    }
}

#Preview {
    NetworkTestView()
} 