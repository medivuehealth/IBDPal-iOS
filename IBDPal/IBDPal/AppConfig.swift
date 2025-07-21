import Foundation

struct AppConfig {
    // MARK: - Server Configuration
    static let serverBaseURL = "https://ibdpal-server-production.up.railway.app" // Railway production server
    static let apiBaseURL = "\(serverBaseURL)/api"
    
    // MARK: - API Endpoints
    struct Endpoints {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let health = "/health"
        static let users = "/users"
        static let journal = "/journal"
        static let diagnosis = "/diagnosis"
    }
    
    // MARK: - App Configuration
    static let appName = "IBDPal"
    static let appVersion = "1.0.0"
    static let appDescription = "Pediatric IBD Care Mobile App"
    
    // MARK: - Network Configuration
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetries = 3
    
    // MARK: - Feature Flags
    static let enableLogging = true
    static let enableDebugMode = true
    
    // MARK: - Validation Rules
    struct Validation {
        static let passwordMinLength = 8
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: Double = 0.3
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50
    }
} 