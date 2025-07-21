import Foundation
import Network

class ProxyConfig {
    static let shared = ProxyConfig()
    
    // Proxy settings for development
    #if DEBUG
    static let useProxy = true
    static let proxyHost = "127.0.0.1"  // Localhost for Charles/Proxyman
    static let proxyPort = 8888         // Default Charles port (Proxyman uses 9090)
    #else
    static let useProxy = false
    static let proxyHost = ""
    static let proxyPort = 0
    #endif
    
    static func configureProxy() {
        #if DEBUG
        if useProxy {
            print("🔧 ProxyConfig: Configuring proxy for development")
            print("🔧 ProxyConfig: Host: \(proxyHost), Port: \(proxyPort)")
            
            // Set system proxy (this is a simplified approach)
            // In a real app, you'd configure URLSession with proxy settings
        }
        #endif
    }
    
    static func createProxyURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        
        #if DEBUG
        if useProxy {
            // Note: iOS doesn't support proxy configuration in URLSession
            // The proxy will be handled at the system level by Proxyman
            print("🔧 ProxyConfig: Proxy should be configured at system level")
            print("🔧 ProxyConfig: Use Proxyman's system proxy feature")
        }
        #endif
        
        return URLSession(configuration: config)
    }
} 