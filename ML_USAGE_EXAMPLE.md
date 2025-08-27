# ML Flare Prediction Usage Example

## Quick Start

### 1. Test the System
```swift
// In any SwiftUI view or app code
FlarePredictionTest.runTest()
```

This will run a test prediction and print results to the console.

### 2. Add to Your App
```swift
// In ContentView.swift or your main navigation
import SwiftUI

struct ContentView: View {
    @StateObject private var mlEngine = FlarePredictionMLEngine.shared
    @State private var userData: UserData?
    @State private var journalEntries: [JournalEntry] = []
    
    var body: some View {
        TabView {
            // Add Flare Prediction Tab
            FlarePredictionView(
                userData: userData ?? UserData(id: "", email: "", name: "", token: ""),
                journalEntries: journalEntries
            )
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("Predictions")
            }
            
            // ... your existing tabs
        }
    }
}
```

### 3. Use in HomeView
```swift
// In HomeView.swift
struct HomeView: View {
    let userData: UserData?
    @State private var journalEntries: [JournalEntry] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add Flare Prediction Card
                FlarePredictionView(
                    userData: userData ?? UserData(id: "", email: "", name: "", token: ""),
                    journalEntries: journalEntries
                )
                
                // ... your existing content
            }
        }
    }
}
```

## What You Get

### ✅ Real-time Predictions
- Analyzes your journal entries instantly
- Shows current flare risk level
- Updates automatically with new data

### ✅ Risk Assessment
- **Low Risk**: 0-25% probability
- **Moderate Risk**: 25-50% probability  
- **High Risk**: 50-75% probability
- **Critical Risk**: 75-100% probability

### ✅ Personalized Insights
- Contributing factors analysis
- Actionable recommendations
- Risk trend visualization

### ✅ Beautiful UI
- Modern SwiftUI design
- Interactive charts
- Color-coded risk levels

## Data Requirements

The system works with your existing data structures:

```swift
// Your existing UserData
struct UserData: Codable {
    let id: String
    let email: String
    let name: String?
    let token: String
}

// Your existing JournalEntry
struct JournalEntry {
    let id: String
    let date: Date
    let foods: [FoodItem]?
    let beverages: BeverageData?
    let nutrition: NutritionData?
    let symptoms: [String]?
}
```

## Features

### 🔍 Multi-factor Analysis
- **Nutrition**: Fiber, protein, trigger foods, FODMAP score
- **Symptoms**: Pain, diarrhea, bloating, severity
- **Lifestyle**: Stress, sleep, exercise (defaults used)
- **Medication**: Adherence, effectiveness (defaults used)
- **Environmental**: Season, weather patterns
- **Historical**: Previous flares, patterns

### 📊 Smart Predictions
- Rule-based system (fully functional)
- ML-ready framework (for future models)
- Confidence scoring
- Contributing factor analysis

### 🎯 Actionable Recommendations
- Risk-specific action plans
- Priority-based suggestions
- Prevention strategies

## Next Steps

1. **Test the system** with `FlarePredictionTest.runTest()`
2. **Add to your navigation** as a new tab or card
3. **Collect real data** to improve predictions
4. **Train ML models** when you have sufficient data

The system is ready to use and will provide valuable flare predictions based on your user data! 🚀 