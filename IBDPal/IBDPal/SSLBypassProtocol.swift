import Foundation
import Security

class SSLBypassProtocol: URLProtocol {
    
    private var session: URLSession!
    private var dataTask: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        #if DEBUG
        // Only handle HTTPS requests in debug mode
        return request.url?.scheme?.lowercased() == "https"
        #else
        return false
        #endif
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        print("🔓 SSLBypassProtocol: Starting request for \(request.url?.absoluteString ?? "unknown")")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        
        let delegate = SSLBypassDelegate()
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("🔓 SSLBypassProtocol: Error - \(error.localizedDescription)")
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    print("🔓 SSLBypassProtocol: Success - \(response)")
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
}

class SSLBypassDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("🔓 SSLBypassDelegate: SSL Challenge received for \(challenge.protectionSpace.host)")
        print("🔓 SSLBypassDelegate: Challenge type: \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            print("🔓 SSLBypassDelegate: Server trust challenge")
            
            if let serverTrust = challenge.protectionSpace.serverTrust {
                // Try to load and add certificates
                let certificates = loadCertificates()
                if !certificates.isEmpty {
                    print("🔓 SSLBypassDelegate: Adding \(certificates.count) certificates to trust")
                    SecTrustSetAnchorCertificates(serverTrust, certificates as CFArray)
                }
                
                // Set trust result to proceed (using modern API)
                var error: CFError?
                let isValid = SecTrustEvaluateWithError(serverTrust, &error)
                
                print("🔓 SSLBypassDelegate: Trust evaluation result: \(isValid)")
                if let error = error {
                    print("🔓 SSLBypassDelegate: Trust error: \(error)")
                }
                
                if isValid {
                    let credential = URLCredential(trust: serverTrust)
                    print("🔓 SSLBypassDelegate: Using credential with trust")
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }
        
        // Fallback: accept all challenges
        print("🔓 SSLBypassDelegate: Accepting all SSL challenges")
        completionHandler(.useCredential, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("🔓 SSLBypassDelegate: Task error - \(error.localizedDescription)")
        }
    }
    
    // Load certificates from the app bundle
    private func loadCertificates() -> [SecCertificate] {
        var certificates: [SecCertificate] = []
        
        // Load UmbrellaRoot certificate
        if let umbrellaCert = loadCertificate(named: "UmbrellaRoot", type: "crt") {
            certificates.append(umbrellaCert)
            print("🔓 SSLBypassDelegate: UmbrellaRoot certificate loaded")
        }
        
        // Load EPRI-ROOT-CA certificate
        if let epriCert = loadCertificate(named: "EPRI-ROOT-CA", type: "crt") {
            certificates.append(epriCert)
            print("🔓 SSLBypassDelegate: EPRI-ROOT-CA certificate loaded")
        }
        
        print("🔓 SSLBypassDelegate: Total certificates loaded: \(certificates.count)")
        return certificates
    }
    
    // Helper function to load a single certificate
    private func loadCertificate(named name: String, type: String) -> SecCertificate? {
        guard let certPath = Bundle.main.path(forResource: name, ofType: type) else {
            print("🔓 SSLBypassDelegate: \(name).\(type) certificate not found in bundle")
            return nil
        }
        
        guard let certData = NSData(contentsOfFile: certPath) else {
            print("🔓 SSLBypassDelegate: Could not read \(name).\(type) certificate data")
            return nil
        }
        
        guard let certificate = SecCertificateCreateWithData(nil, certData) else {
            print("🔓 SSLBypassDelegate: Could not create certificate from \(name).\(type) data")
            return nil
        }
        
        return certificate
    }
}

// Register the protocol when the app starts
extension SSLBypassProtocol {
    static func register() {
        print("🔓 SSLBypassProtocol: Registering custom protocol")
        URLProtocol.registerClass(SSLBypassProtocol.self)
    }
    
    static func unregister() {
        print("🔓 SSLBypassProtocol: Unregistering custom protocol")
        URLProtocol.unregisterClass(SSLBypassProtocol.self)
    }
} 