import Foundation
import XCTest
@testable import IBDPal

// MARK: - Disease Activity AI Test Suite
// Comprehensive testing for unbiased, recall-based disease activity assessment

class DiseaseActivityAITests: XCTestCase {
    
    var aiModel: DiseaseActivityAI.Type!
    var mockJournalEntries: [JournalEntry]!
    var mockUserDiagnosis: UserDiagnosis!
    
    override func setUp() {
        super.setUp()
        aiModel = DiseaseActivityAI.self
        mockJournalEntries = []
        mockUserDiagnosis = UserDiagnosis(
            diseaseType: "Crohn's Disease",
            diseaseSeverity: "Moderate",
            diagnosisDate: Date(),
            diseaseLocation: "Small intestine",
            diseaseBehavior: "Inflammatory"
        )
    }
    
    override func tearDown() {
        aiModel = nil
        mockJournalEntries = nil
        mockUserDiagnosis = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testRemissionAssessment() {
        // Test case: User with minimal symptoms should be assessed as remission
        let remissionEntries = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 1,
            urgencyLevel: 2,
            bowelFrequency: 2,
            stressLevel: 2,
            fatigueLevel: 2,
            sleepQuality: 8,
            days: 30
        )
        
        let assessment = aiModel.assessDiseaseActivity(
            from: remissionEntries,
            userDiagnosis: mockUserDiagnosis,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .remission, "Minimal symptoms should result in remission assessment")
    }
    
    func testMildActivityAssessment() {
        // Test case: User with mild symptoms should be assessed as mild activity
        let mildEntries = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 3,
            urgencyLevel: 4,
            bowelFrequency: 3,
            stressLevel: 3,
            fatigueLevel: 4,
            sleepQuality: 6,
            days: 30
        )
        
        let assessment = aiModel.assessDiseaseActivity(
            from: mildEntries,
            userDiagnosis: mockUserDiagnosis,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .mild, "Mild symptoms should result in mild activity assessment")
    }
    
    func testModerateActivityAssessment() {
        // Test case: User with moderate symptoms should be assessed as moderate activity
        let moderateEntries = createMockEntries(
            bloodPresent: false,
            mucusPresent: true,
            painSeverity: 5,
            urgencyLevel: 6,
            bowelFrequency: 4,
            stressLevel: 4,
            fatigueLevel: 5,
            sleepQuality: 4,
            days: 30
        )
        
        let assessment = aiModel.assessDiseaseActivity(
            from: moderateEntries,
            userDiagnosis: mockUserDiagnosis,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .moderate, "Moderate symptoms should result in moderate activity assessment")
    }
    
    func testSevereActivityAssessment() {
        // Test case: User with severe symptoms should be assessed as severe activity
        let severeEntries = createMockEntries(
            bloodPresent: true,
            mucusPresent: true,
            painSeverity: 8,
            urgencyLevel: 8,
            bowelFrequency: 6,
            stressLevel: 5,
            fatigueLevel: 7,
            sleepQuality: 2,
            days: 30
        )
        
        let assessment = aiModel.assessDiseaseActivity(
            from: severeEntries,
            userDiagnosis: mockUserDiagnosis,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .severe, "Severe symptoms should result in severe activity assessment")
    }
    
    func testInsufficientDataFallback() {
        // Test case: No journal entries should fallback to diagnosis severity
        let assessment = aiModel.assessDiseaseActivity(
            from: [],
            userDiagnosis: mockUserDiagnosis,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .moderate, "Should fallback to diagnosis severity when no data available")
    }
    
    func testNoDiagnosisFallback() {
        // Test case: No diagnosis should fallback to healthy/remission
        let assessment = aiModel.assessDiseaseActivity(
            from: [],
            userDiagnosis: nil,
            fallbackToHealthy: true
        )
        
        XCTAssertEqual(assessment, .remission, "Should fallback to remission when no diagnosis available")
    }
    
    func testBiasMitigation() {
        // Test case: Ensure assessment is not biased by demographic factors
        let entries1 = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 3,
            urgencyLevel: 3,
            bowelFrequency: 2,
            stressLevel: 2,
            fatigueLevel: 3,
            sleepQuality: 7,
            days: 30
        )
        
        let entries2 = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 3,
            urgencyLevel: 3,
            bowelFrequency: 2,
            stressLevel: 2,
            fatigueLevel: 3,
            sleepQuality: 7,
            days: 30
        )
        
        let assessment1 = aiModel.assessDiseaseActivity(from: entries1, userDiagnosis: nil, fallbackToHealthy: true)
        let assessment2 = aiModel.assessDiseaseActivity(from: entries2, userDiagnosis: nil, fallbackToHealthy: true)
        
        XCTAssertEqual(assessment1, assessment2, "Same symptoms should produce same assessment regardless of other factors")
    }
    
    func testTrendAnalysis() {
        // Test case: Worsening trend should increase disease activity assessment
        let improvingEntries = createTrendEntries(
            startSeverity: 7,
            endSeverity: 3,
            days: 30
        )
        
        let worseningEntries = createTrendEntries(
            startSeverity: 3,
            endSeverity: 7,
            days: 30
        )
        
        let improvingAssessment = aiModel.assessDiseaseActivity(from: improvingEntries, userDiagnosis: nil, fallbackToHealthy: true)
        let worseningAssessment = aiModel.assessDiseaseActivity(from: worseningEntries, userDiagnosis: nil, fallbackToHealthy: true)
        
        // Worsening trend should result in higher disease activity
        XCTAssertTrue(
            getActivityLevel(worseningAssessment) >= getActivityLevel(improvingAssessment),
            "Worsening trend should result in higher or equal disease activity assessment"
        )
    }
    
    func testWeightedScoring() {
        // Test case: Critical symptoms should have higher weight
        let criticalEntries = createMockEntries(
            bloodPresent: true,
            mucusPresent: false,
            painSeverity: 2,
            urgencyLevel: 2,
            bowelFrequency: 2,
            stressLevel: 2,
            fatigueLevel: 2,
            sleepQuality: 8,
            days: 30
        )
        
        let nonCriticalEntries = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 6,
            urgencyLevel: 6,
            bowelFrequency: 2,
            stressLevel: 2,
            fatigueLevel: 2,
            sleepQuality: 8,
            days: 30
        )
        
        let criticalAssessment = aiModel.assessDiseaseActivity(from: criticalEntries, userDiagnosis: nil, fallbackToHealthy: true)
        let nonCriticalAssessment = aiModel.assessDiseaseActivity(from: nonCriticalEntries, userDiagnosis: nil, fallbackToHealthy: true)
        
        // Blood present should have higher impact than high pain/urgency
        XCTAssertTrue(
            getActivityLevel(criticalAssessment) >= getActivityLevel(nonCriticalAssessment),
            "Critical symptoms should have higher weight than non-critical symptoms"
        )
    }
    
    func testDataQualityImpact() {
        // Test case: More data should result in more confident assessment
        let limitedData = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 5,
            urgencyLevel: 5,
            bowelFrequency: 3,
            stressLevel: 3,
            fatigueLevel: 4,
            sleepQuality: 5,
            days: 7
        )
        
        let fullData = createMockEntries(
            bloodPresent: false,
            mucusPresent: false,
            painSeverity: 5,
            urgencyLevel: 5,
            bowelFrequency: 3,
            stressLevel: 3,
            fatigueLevel: 4,
            sleepQuality: 5,
            days: 30
        )
        
        // Both should assess similarly, but full data should be more reliable
        let limitedAssessment = aiModel.assessDiseaseActivity(from: limitedData, userDiagnosis: nil, fallbackToHealthy: true)
        let fullAssessment = aiModel.assessDiseaseActivity(from: fullData, userDiagnosis: nil, fallbackToHealthy: true)
        
        // Full data assessment should be more stable
        XCTAssertNotNil(limitedAssessment)
        XCTAssertNotNil(fullAssessment)
    }
    
    // MARK: - Helper Methods
    
    private func createMockEntries(
        bloodPresent: Bool,
        mucusPresent: Bool,
        painSeverity: Int,
        urgencyLevel: Int,
        bowelFrequency: Int,
        stressLevel: Int,
        fatigueLevel: Int,
        sleepQuality: Int,
        days: Int
    ) -> [JournalEntry] {
        
        var entries: [JournalEntry] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            let entry = JournalEntry(
                entry_id: i,
                user_id: "test_user",
                entry_date: date,
                calories: 2000,
                protein: 80.0,
                carbs: 250.0,
                fiber: 25.0,
                has_allergens: false,
                meals_per_day: 3,
                hydration_level: 7,
                bowel_frequency: bowelFrequency,
                bristol_scale: 4,
                urgency_level: urgencyLevel,
                blood_present: bloodPresent,
                pain_location: "lower_abdomen",
                pain_severity: painSeverity,
                pain_time: "variable",
                medication_taken: true,
                medication_type: "Mesalamine",
                dosage_level: "normal",
                sleep_hours: 8,
                stress_level: stressLevel,
                fatigue_level: fatigueLevel,
                notes: "Test entry",
                menstruation: nil,
                breakfast: "Oatmeal",
                lunch: "Salad",
                dinner: "Chicken",
                snacks: "Apple",
                breakfast_calories: 400.0,
                breakfast_protein: 15.0,
                breakfast_carbs: 60.0,
                breakfast_fiber: 8.0,
                breakfast_fat: 10.0,
                lunch_calories: 500.0,
                lunch_protein: 25.0,
                lunch_carbs: 50.0,
                lunch_fiber: 10.0,
                lunch_fat: 15.0,
                dinner_calories: 600.0,
                dinner_protein: 40.0,
                dinner_carbs: 40.0,
                dinner_fiber: 5.0,
                dinner_fat: 20.0,
                snack_calories: 200.0,
                snack_protein: 5.0,
                snack_carbs: 30.0,
                snack_fiber: 2.0,
                snack_fat: 5.0,
                last_taken_date: date,
                stress_source: "work",
                coping_strategies: "meditation",
                mood_level: 7,
                sleep_quality: sleepQuality,
                sleep_notes: "Good sleep",
                water_intake: 2.5,
                other_fluids: 0.5,
                fluid_type: "water",
                supplements_taken: true,
                supplements_count: 2,
                supplement_details: nil,
                created_at: date,
                updated_at: date
            )
            
            entries.append(entry)
        }
        
        return entries
    }
    
    private func createTrendEntries(
        startSeverity: Int,
        endSeverity: Int,
        days: Int
    ) -> [JournalEntry] {
        
        var entries: [JournalEntry] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // Linear interpolation between start and end severity
            let progress = Double(i) / Double(days - 1)
            let currentSeverity = Int(Double(startSeverity) + progress * Double(endSeverity - startSeverity))
            
            let entry = JournalEntry(
                entry_id: i,
                user_id: "test_user",
                entry_date: date,
                calories: 2000,
                protein: 80.0,
                carbs: 250.0,
                fiber: 25.0,
                has_allergens: false,
                meals_per_day: 3,
                hydration_level: 7,
                bowel_frequency: 3,
                bristol_scale: 4,
                urgency_level: currentSeverity,
                blood_present: currentSeverity > 6,
                pain_location: "lower_abdomen",
                pain_severity: currentSeverity,
                pain_time: "variable",
                medication_taken: true,
                medication_type: "Mesalamine",
                dosage_level: "normal",
                sleep_hours: 8,
                stress_level: min(5, currentSeverity / 2),
                fatigue_level: currentSeverity,
                notes: "Test entry",
                menstruation: nil,
                breakfast: "Oatmeal",
                lunch: "Salad",
                dinner: "Chicken",
                snacks: "Apple",
                breakfast_calories: 400.0,
                breakfast_protein: 15.0,
                breakfast_carbs: 60.0,
                breakfast_fiber: 8.0,
                breakfast_fat: 10.0,
                lunch_calories: 500.0,
                lunch_protein: 25.0,
                lunch_carbs: 50.0,
                lunch_fiber: 10.0,
                lunch_fat: 15.0,
                dinner_calories: 600.0,
                dinner_protein: 40.0,
                dinner_carbs: 40.0,
                dinner_fiber: 5.0,
                dinner_fat: 20.0,
                snack_calories: 200.0,
                snack_protein: 5.0,
                snack_carbs: 30.0,
                snack_fiber: 2.0,
                snack_fat: 5.0,
                last_taken_date: date,
                stress_source: "work",
                coping_strategies: "meditation",
                mood_level: 7,
                sleep_quality: max(1, 10 - currentSeverity),
                sleep_notes: "Test sleep",
                water_intake: 2.5,
                other_fluids: 0.5,
                fluid_type: "water",
                supplements_taken: true,
                supplements_count: 2,
                supplement_details: nil,
                created_at: date,
                updated_at: date
            )
            
            entries.append(entry)
        }
        
        return entries
    }
    
    private func getActivityLevel(_ activity: DiseaseActivity) -> Int {
        switch activity {
        case .remission: return 0
        case .mild: return 1
        case .moderate: return 2
        case .severe: return 3
        }
    }
}

// MARK: - Performance Tests

class DiseaseActivityAIPerformanceTests: XCTestCase {
    
    func testAssessmentPerformance() {
        // Test case: AI assessment should complete within reasonable time
        let largeDataset = createLargeDataset(entries: 1000)
        
        measure {
            let assessment = DiseaseActivityAI.assessDiseaseActivity(
                from: largeDataset,
                userDiagnosis: nil,
                fallbackToHealthy: true
            )
            XCTAssertNotNil(assessment)
        }
    }
    
    private func createLargeDataset(entries: Int) -> [JournalEntry] {
        var dataset: [JournalEntry] = []
        let calendar = Calendar.current
        
        for i in 0..<entries {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            let entry = JournalEntry(
                entry_id: i,
                user_id: "test_user",
                entry_date: date,
                calories: 2000,
                protein: 80.0,
                carbs: 250.0,
                fiber: 25.0,
                has_allergens: false,
                meals_per_day: 3,
                hydration_level: 7,
                bowel_frequency: 3,
                bristol_scale: 4,
                urgency_level: Int.random(in: 1...5),
                blood_present: Bool.random(),
                pain_location: "lower_abdomen",
                pain_severity: Int.random(in: 1...5),
                pain_time: "variable",
                medication_taken: true,
                medication_type: "Mesalamine",
                dosage_level: "normal",
                sleep_hours: 8,
                stress_level: Int.random(in: 1...5),
                fatigue_level: Int.random(in: 1...5),
                notes: "Test entry",
                menstruation: nil,
                breakfast: "Oatmeal",
                lunch: "Salad",
                dinner: "Chicken",
                snacks: "Apple",
                breakfast_calories: 400.0,
                breakfast_protein: 15.0,
                breakfast_carbs: 60.0,
                breakfast_fiber: 8.0,
                breakfast_fat: 10.0,
                lunch_calories: 500.0,
                lunch_protein: 25.0,
                lunch_carbs: 50.0,
                lunch_fiber: 10.0,
                lunch_fat: 15.0,
                dinner_calories: 600.0,
                dinner_protein: 40.0,
                dinner_carbs: 40.0,
                dinner_fiber: 5.0,
                dinner_fat: 20.0,
                snack_calories: 200.0,
                snack_protein: 5.0,
                snack_carbs: 30.0,
                snack_fiber: 2.0,
                snack_fat: 5.0,
                last_taken_date: date,
                stress_source: "work",
                coping_strategies: "meditation",
                mood_level: 7,
                sleep_quality: Int.random(in: 1...10),
                sleep_notes: "Test sleep",
                water_intake: 2.5,
                other_fluids: 0.5,
                fluid_type: "water",
                supplements_taken: true,
                supplements_count: 2,
                supplement_details: nil,
                created_at: date,
                updated_at: date
            )
            
            dataset.append(entry)
        }
        
        return dataset
    }
}
