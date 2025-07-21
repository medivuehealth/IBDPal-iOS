import Foundation
import SwiftUI

class NetworkLogger: ObservableObject {
    static let shared = NetworkLogger()
    
    @Published var logs: [NetworkLogEntry] = []
    @Published var isVisible = false
    
    private let maxLogs = 100
    
    func log(_ message: String, level: LogLevel = .info, category: LogCategory = .general) {
        let entry = NetworkLogEntry(
            timestamp: Date(),
            message: message,
            level: level,
            category: category
        )
        
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            if self.logs.count > self.maxLogs {
                self.logs.removeLast()
            }
        }
        
        // Also print to console for immediate debugging
        print("[\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)")
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func exportLogs() -> String {
        return logs.map { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return "[\(formatter.string(from: entry.timestamp))] [\(entry.level.rawValue.uppercased())] [\(entry.category.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

struct NetworkLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel
    let category: LogCategory
}

enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

enum LogCategory: String, CaseIterable {
    case general = "general"
    case network = "network"
    case auth = "auth"
    case api = "api"
    case ui = "ui"
    case journal = "journal"
}

// Network monitoring extension
extension NetworkLogger {
    func logNetworkRequest(_ request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "Unknown"
        
        log("🌐 \(method) \(url)", level: .info, category: .network)
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log("📋 Headers: \(headers)", level: .debug, category: .network)
        }
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            log("📦 Request Body: \(bodyString)", level: .debug, category: .network)
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            log("📥 Response: \(httpResponse.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))", 
                level: httpResponse.statusCode >= 400 ? .error : .info, 
                category: .network)
            
            if let responseHeaders = httpResponse.allHeaderFields as? [String: String] {
                log("📋 Response Headers: \(responseHeaders)", level: .debug, category: .network)
            }
        }
        
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            log("📄 Response Data: \(responseString)", level: .debug, category: .network)
        }
        
        if let error = error {
            log("❌ Network Error: \(error.localizedDescription)", level: .error, category: .network)
            log("🔍 Error Details: \(error)", level: .debug, category: .network)
        }
    }
    
    func logServerConnectionTest(_ baseURL: String) {
        log("🔍 Testing server connection to: \(baseURL)", level: .info, category: .network)
        
        guard let url = URL(string: baseURL) else {
            log("❌ Invalid URL: \(baseURL)", level: .error, category: .network)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                self.log("❌ Connection failed: \(error.localizedDescription)", level: .error, category: .network)
                
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case NSURLErrorCannotConnectToHost:
                        self.log("🔍 Server is not reachable - check if server is running", level: .error, category: .network)
                    case NSURLErrorNetworkConnectionLost:
                        self.log("🔍 Network connection lost", level: .error, category: .network)
                    case NSURLErrorTimedOut:
                        self.log("🔍 Request timed out - server may be slow or unreachable", level: .error, category: .network)
                    case NSURLErrorNotConnectedToInternet:
                        self.log("🔍 No internet connection", level: .error, category: .network)
                    default:
                        self.log("🔍 Network error code: \(nsError.code)", level: .error, category: .network)
                    }
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                self.log("✅ Server is reachable - Status: \(httpResponse.statusCode)", level: .info, category: .network)
            } else {
                self.log("⚠️ Received response but not HTTP", level: .warning, category: .network)
            }
        }
        
        task.resume()
    }
} 