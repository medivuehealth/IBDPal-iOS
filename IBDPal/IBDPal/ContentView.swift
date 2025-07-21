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
            MainTabView(userData: $userData)
        } else {
            LoginView(isAuthenticated: $isAuthenticated, userData: $userData)
        }
    }
}

struct MainTabView: View {
    @Binding var userData: UserData?
    
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
                    Text("Discover")
                }
            
            SearchView(userData: userData)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            MoreView(userData: userData)
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
    let token: String
}

#Preview {
    ContentView()
}
