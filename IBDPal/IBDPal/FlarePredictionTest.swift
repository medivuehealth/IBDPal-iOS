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
            phoneNumber: nil,
            token: "test-token"
        )
    }
    
    private static func createMockJournalEntries() -> [JournalEntry] {
        // Create mock journal entries for testing using the actual JournalEntry structure
        let mockEntry = JournalEntry(
            entry_id: "test-entry-1",
            user_id: "test-user-id",
            entry_date: "2024-01-15",
            meals: [
                createMockMeal()
            ],
            symptoms: [
                createMockSymptom()
            ],
            bowel_movements: nil,
            bowel_frequency: 2,
            blood_present: false,
            mucus_present: false,
            pain_severity: 3,
            pain_location: "abdomen",
            urgency_level: 4,
            bristol_scale: 4,
            hydration: 2000,
            water_intake: "2.0",
            other_fluids: "0.5",
            fluid_type: "Water",
            notes: "Test entry",
            created_at: "2024-01-15T10:00:00Z",
            updated_at: "2024-01-15T10:00:00Z",
            // Direct nutrition fields
            calories: 1500.0,
            protein: 75.0,
            carbs: 150.0,
            fiber: 25.0,
            fat: 60.0,
            // Individual meal nutrition fields
            breakfast_calories: 400.0,
            breakfast_protein: 15.0,
            breakfast_carbs: 50.0,
            breakfast_fiber: 8.0,
            breakfast_fat: 15.0,
            lunch_calories: 500.0,
            lunch_protein: 30.0,
            lunch_carbs: 40.0,
            lunch_fiber: 10.0,
            lunch_fat: 20.0,
            dinner_calories: 600.0,
            dinner_protein: 30.0,
            dinner_carbs: 60.0,
            dinner_fiber: 7.0,
            dinner_fat: 25.0,
            snack_calories: 0.0,
            snack_protein: 0.0,
            snack_carbs: 0.0,
            snack_fiber: 0.0,
            snack_fat: 0.0,
            // Medication fields
            medication_taken: false,
            medication_type: "None",
            dosage_level: "0",
            last_taken_date: nil,
            // Supplement fields
            supplements_taken: false,
            supplements_count: 0,
            supplement_details: nil,
            // Sleep fields
            sleep_hours: 8,
            sleep_quality: 4,
            sleep_notes: nil,
            // Stress fields
            stress_level: 2,
            stress_source: nil,
            coping_strategies: nil,
            // Additional fields
            fatigue_level: 3,
            mood_level: 4,
            menstruation: "not_applicable"
        )
        
        return [mockEntry]
    }
    
    private static func createMockMeal() -> Meal {
        // Create mock meal using the actual Meal structure
        return Meal(
            meal_id: "test-meal-1",
            meal_type: "breakfast",
            description: "Chicken Breast",
            calories: 165,
            protein: 31,
            carbs: 0,
            fiber: 0,
            fat: 4,
            serving_size: 1.0,
            serving_unit: "cup",
            serving_description: "1 cup"
        )
    }
    
    private static func createMockSymptom() -> Symptom {
        // Create mock symptom using the actual Symptom structure
        return Symptom(
            symptom_id: "test-symptom-1",
            type: "abdominal_pain",
            severity: 5,
            notes: "Test symptom"
        )
    }
} 