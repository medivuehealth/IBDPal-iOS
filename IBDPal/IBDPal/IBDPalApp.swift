//
//  IBDPalApp.swift
//  IBDPal
//
//  Created by Subramani Shashi Kumar on 7/19/25.
//

import SwiftUI

@main
struct IBDPalApp: App {
    
    init() {
        #if DEBUG
        // Register SSL bypass protocol for development
        SSLBypassProtocol.register()
        print("🚀 IBDPalApp: SSL bypass protocol registered")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
