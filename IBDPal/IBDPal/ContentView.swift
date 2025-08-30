//
//  ContentView.swift
//  IBDPal
//
//  Created by Subramani Shashi Kumar on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var userData: UserData?
    
    var body: some View {
        if isAuthenticated {
            MainTabView(userData: $userData, onSignOut: handleSignOut)
        } else {
            LoginView(isAuthenticated: $isAuthenticated, userData: $userData)
        }
    }
    
    private func handleSignOut() {
        // Clear authentication state
        isAuthenticated = false
        userData = nil
        print("✅ [ContentView] User signed out successfully")
    }
}

struct MainTabView: View {
    @Binding var userData: UserData?
    let onSignOut: () -> Void
    
    var body: some View {
        TabView {
            HomeView(userData: userData)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            DailyLogView(userData: userData)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Daily Log")
                }
            
            DiscoverView(userData: userData)
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Trends")
                }
            
            SearchView(userData: userData)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Connect")
                }
            
            MoreView(userData: userData, onSignOut: onSignOut)
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("More")
                }
        }
        .accentColor(.blue)
    }
}

struct UserData: Codable {
    let id: String  // Changed from Int to String to match server UUID format
    let email: String
    let name: String?
    let phoneNumber: String?
    let token: String
}

#Preview {
    ContentView()
}
