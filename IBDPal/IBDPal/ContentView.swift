//
//  ContentView.swift
//  IBDPal
//
//  Created by Subramani Shashi Kumar on 7/19/25.
//

import SwiftUI

// MARK: - Shared Data Manager
class DataRefreshManager: ObservableObject {
    @Published var refreshTrigger = UUID()
    
    func refreshData() {
        refreshTrigger = UUID()
        print("🔄 [DataRefreshManager] Data refresh triggered")
    }
}

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var userData: UserData?
    @StateObject private var dataRefreshManager = DataRefreshManager()
    
    var body: some View {
        if isAuthenticated {
            MainTabView(userData: $userData, onSignOut: handleSignOut, dataRefreshManager: dataRefreshManager)
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
    @ObservedObject var dataRefreshManager: DataRefreshManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userData: userData, dataRefreshManager: dataRefreshManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .onAppear {
                    // Refresh HomeView data when Home tab is selected
                    print("🏠 [MainTabView] Home tab selected - refreshing data")
                    dataRefreshManager.refreshData()
                }
            
            DailyLogView(userData: userData, dataRefreshManager: dataRefreshManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Daily Log")
                }
                .tag(1)
            
            DiscoverView(userData: userData)
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Trends")
                }
                .tag(2)
            
            SearchView(userData: userData)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Connect")
                }
                .tag(3)
            
            MoreView(userData: userData, onSignOut: onSignOut)
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("More")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newTab in
            // Refresh HomeView when switching back to Home tab
            if newTab == 0 {
                print("🏠 [MainTabView] Switched to Home tab - refreshing data")
                dataRefreshManager.refreshData()
            }
        }
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
