import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let id = UUID().uuidString
    
    private init() {
        print("🔧 NetworkManager: Initializing...")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        // Charles Proxy handles SSL interception, so we use standard configuration
        print("🔧 NetworkManager: Using standard configuration with Charles Proxy")
        
        self.session = URLSession(configuration: config)
        
        print("🔧 NetworkManager: Initialization complete (ID: \(id))")
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        print("🔧 NetworkManager [\(id)]: Creating data task for \(request.url?.absoluteString ?? "unknown")")
        return session.dataTask(with: request, completionHandler: completionHandler)
    }
    
    // Add a simple fetch method for journal entries
    func fetchJournalEntries(userId: String) async throws -> [JournalEntry] {
        // This is a placeholder implementation
        // In a real app, this would make an API call
        return []
    }
} 