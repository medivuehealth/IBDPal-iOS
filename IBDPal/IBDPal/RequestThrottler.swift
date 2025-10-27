import Foundation

/// Manages API request throttling to prevent rate limiting
class RequestThrottler: ObservableObject {
    static let shared = RequestThrottler()
    
    private var lastRequestTime: Date = Date.distantPast
    private var requestCount = 0
    private var requestWindowStart = Date()
    private let queue = DispatchQueue(label: "com.ibdpal.requestthrottler", qos: .utility)
    
    private init() {}
    
    /// Throttles API requests to prevent rate limiting
    /// - Parameter completion: Block to execute after throttling delay
    func throttleRequest(completion: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Reset request count if we're in a new minute
            let now = Date()
            if now.timeIntervalSince(self.requestWindowStart) >= 60 {
                self.requestCount = 0
                self.requestWindowStart = now
            }
            
            // Check if we've exceeded the rate limit
            if self.requestCount >= AppConfig.maxRequestsPerMinute {
                let waitTime = 60 - now.timeIntervalSince(self.requestWindowStart)
                print("⚠️ [RequestThrottler] Rate limit reached, waiting \(waitTime) seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.requestCount = 0
                    self.requestWindowStart = Date()
                    completion()
                }
                return
            }
            
            // Calculate delay since last request
            let timeSinceLastRequest = now.timeIntervalSince(self.lastRequestTime)
            let delay = max(0, AppConfig.rateLimitDelay - timeSinceLastRequest)
            
            if delay > 0 {
                print("⏱️ [RequestThrottler] Throttling request by \(delay) seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.executeRequest(completion: completion)
                }
            } else {
                self.executeRequest(completion: completion)
            }
        }
    }
    
    private func executeRequest(completion: @escaping () -> Void) {
        lastRequestTime = Date()
        requestCount += 1
        print("📡 [RequestThrottler] Executing request #\(requestCount) this minute")
        completion()
    }
    
    /// Resets the throttler (useful for testing or after long periods of inactivity)
    func reset() {
        queue.async { [weak self] in
            self?.requestCount = 0
            self?.requestWindowStart = Date()
            self?.lastRequestTime = Date.distantPast
        }
    }
}

