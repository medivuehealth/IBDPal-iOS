import Foundation

// Simple test to verify the ML system works
class FlarePredictionTest {
    
    static func testBasicPrediction() async {
        print("🧪 Testing Flare Prediction System...")
        
        // Create mock data using existing structures
        let userData = createMockUserData()
        let journalEntries = createMockJournalEntries()
        
        // Test prediction
        let mlEngine = FlarePredictionMLEngine.shared
        let prediction = await mlEngine.predictFlare(for: userData, journalEntries: journalEntries)
        
        print("✅ Prediction completed:")
        print("   Risk Level: \(prediction.riskLevel.rawValue)")
        print("   Probability: \(Int(prediction.flareProbability * 100))%")
        print("   Confidence: \(Int(prediction.confidenceScore * 100))%")
        print("   Factors: \(prediction.contributingFactors)")
        print("   Recommendations: \(prediction.recommendations.count)")
    }
    
    // Call this from your app to test the ML system
    static func runTest() {
        Task {
            await testBasicPrediction()
        }
    }
    
    private static func createMockUserData() -> UserData {
        // Create mock user data using the actual UserData structure
        return UserData(
            id: "test-user-id",
            email: "test@example.com",
            name: "Test User",
            token: "test-token"
        )
    }
    
    private static func createMockJournalEntries() -> [JournalEntry] {
        // Create mock journal entries for testing using the actual JournalEntry structure
        let mockEntry = JournalEntry(
            id: "test-entry-1",
            date: Date(),
            foods: [
                createMockFoodItem()
            ],
            beverages: BeverageData(totalHydration: 2000.0),
            nutrition: createMockNutritionData(),
            symptoms: ["abdominal_pain", "bloating"]
        )
        
        return [mockEntry]
    }
    
    private static func createMockFoodItem() -> FoodItem {
        // Create mock food item using the actual FoodItem structure
        return FoodItem(
            name: "Chicken Breast",
            quantity: 100.0,
            unit: "g"
        )
    }
    
    private static func createMockNutritionData() -> NutritionData {
        // Create mock nutrition data using the actual NutritionData structure
        return NutritionData(
            calories: 165.0,
            protein: 31.0,
            carbs: 0.0,
            fiber: 0.0,
            fat: 3.6,
            vitamins: ["Vitamin B12": 0.3],
            minerals: ["Iron": 1.2]
        )
    }
} 