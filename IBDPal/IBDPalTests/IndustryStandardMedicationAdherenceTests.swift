import XCTest
@testable import IBDPal

// MARK: - Industry-Standard Medication Adherence Test Suite
// Tests the proper medication adherence calculation based on frequency intervals

class IndustryStandardMedicationAdherenceTests: XCTestCase {
    
    var adherenceCalculator: MedicationAdherenceCalculator!
    var medicationAdherenceService: IndustryStandardMedicationAdherenceService!
    
    override func setUp() {
        super.setUp()
        adherenceCalculator = MedicationAdherenceCalculator.shared
        medicationAdherenceService = IndustryStandardMedicationAdherenceService()
    }
    
    override func tearDown() {
        adherenceCalculator = nil
        medicationAdherenceService = nil
        super.tearDown()
    }
    
    // MARK: - Daily Medication Tests
    
    func testDailyMedicationAdherence_PerfectAdherence() {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        // Create perfect daily adherence records
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            records.append(MedicationIntakeRecord(
                id: UUID().uuidString,
                medicationName: "Mesalamine",
                dateTaken: currentDate,
                dosage: "400mg",
                notes: "Taken as prescribed",
                userId: "test_user"
            ))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.adherencePercentage, 100.0, accuracy: 0.1, "Perfect daily adherence should be 100%")
        XCTAssertEqual(result.actualDoses, records.count, "Actual doses should match record count")
    }
    
    func testDailyMedicationAdherence_PartialAdherence() {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        // Create 80% adherence (24 out of 30 days)
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        for i in 0..<30 {
            if i % 5 != 0 { // Skip every 5th day (80% adherence)
                records.append(MedicationIntakeRecord(
                    id: UUID().uuidString,
                    medicationName: "Mesalamine",
                    dateTaken: currentDate,
                    dosage: "400mg",
                    notes: "Taken as prescribed",
                    userId: "test_user"
                ))
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.adherencePercentage, 80.0, accuracy: 1.0, "80% adherence should be calculated correctly")
        XCTAssertEqual(result.actualDoses, 24, "Should have 24 actual doses")
        XCTAssertEqual(result.expectedDoses, 30, "Should expect 30 doses for 30 days")
    }
    
    // MARK: - Weekly Medication Tests
    
    func testWeeklyMedicationAdherence() {
        let startDate = Calendar.current.date(byAdding: .day, value: -28, to: Date())! // 4 weeks
        let endDate = Date()
        
        // Create weekly adherence records
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        for week in 0..<4 {
            let weekDate = Calendar.current.date(byAdding: .weekOfYear, value: week, to: startDate)!
            records.append(MedicationIntakeRecord(
                id: UUID().uuidString,
                medicationName: "Infliximab",
                dateTaken: weekDate,
                dosage: "5mg/kg",
                notes: "Weekly infusion",
                userId: "test_user"
            ))
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .weekly,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.adherencePercentage, 100.0, accuracy: 0.1, "Perfect weekly adherence should be 100%")
        XCTAssertEqual(result.actualDoses, 4, "Should have 4 actual doses")
        XCTAssertEqual(result.expectedDoses, 4, "Should expect 4 doses for 4 weeks")
    }
    
    // MARK: - Bi-Weekly Medication Tests
    
    func testBiWeeklyMedicationAdherence() {
        let startDate = Calendar.current.date(byAdding: .day, value: -28, to: Date())! // 4 weeks
        let endDate = Date()
        
        // Create bi-weekly adherence records
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        for biWeek in 0..<2 {
            let biWeekDate = Calendar.current.date(byAdding: .day, value: biWeek * 14, to: startDate)!
            records.append(MedicationIntakeRecord(
                id: UUID().uuidString,
                medicationName: "Adalimumab",
                dateTaken: biWeekDate,
                dosage: "40mg",
                notes: "Bi-weekly injection",
                userId: "test_user"
            ))
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .biWeekly,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.adherencePercentage, 100.0, accuracy: 0.1, "Perfect bi-weekly adherence should be 100%")
        XCTAssertEqual(result.actualDoses, 2, "Should have 2 actual doses")
        XCTAssertEqual(result.expectedDoses, 2, "Should expect 2 doses for 4 weeks bi-weekly")
    }
    
    // MARK: - Monthly Averages Tests
    
    func testMonthlyAveragesCalculation() {
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let endDate = Date()
        
        // Create records spanning 3 months
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            // Add some variation in adherence
            if Double.random(in: 0...1) > 0.2 { // 80% adherence
                records.append(MedicationIntakeRecord(
                    id: UUID().uuidString,
                    medicationName: "Mesalamine",
                    dateTaken: currentDate,
                    dosage: "400mg",
                    notes: "Daily medication",
                    userId: "test_user"
                ))
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertFalse(result.monthlyAverages.isEmpty, "Should have monthly averages")
        XCTAssertEqual(result.monthlyAverages.count, 3, "Should have 3 months of data")
        
        // Verify each month has data
        for monthlyData in result.monthlyAverages {
            XCTAssertGreaterThan(monthlyData.expectedDoses, 0, "Each month should have expected doses")
            XCTAssertGreaterThanOrEqual(monthlyData.actualDoses, 0, "Each month should have actual doses")
            XCTAssertGreaterThanOrEqual(monthlyData.adherencePercentage, 0, "Each month should have adherence percentage")
        }
    }
    
    // MARK: - Quality Metrics Tests
    
    func testTimingConsistencyCalculation() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        // Create records with consistent timing
        var records: [MedicationIntakeRecord] = []
        var currentDate = startDate
        
        for i in 0..<7 {
            let exactTime = Calendar.current.date(byAdding: .hour, value: 8, to: currentDate)! // 8 AM each day
            records.append(MedicationIntakeRecord(
                id: UUID().uuidString,
                medicationName: "Mesalamine",
                dateTaken: exactTime,
                dosage: "400mg",
                notes: "Consistent timing",
                userId: "test_user"
            ))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertGreaterThan(result.qualityMetrics.timingConsistency, 80.0, "Consistent timing should have high consistency score")
    }
    
    func testGapAnalysisCalculation() {
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let endDate = Date()
        
        // Create records with gaps
        var records: [MedicationIntakeRecord] = []
        
        // Add records with gaps
        records.append(MedicationIntakeRecord(
            id: "1",
            medicationName: "Mesalamine",
            dateTaken: startDate,
            dosage: "400mg",
            notes: "First dose",
            userId: "test_user"
        ))
        
        // Skip 3 days
        let gapDate = Calendar.current.date(byAdding: .day, value: 4, to: startDate)!
        records.append(MedicationIntakeRecord(
            id: "2",
            medicationName: "Mesalamine",
            dateTaken: gapDate,
            dosage: "400mg",
            notes: "After gap",
            userId: "test_user"
        ))
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: records,
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertGreaterThan(result.qualityMetrics.gapAnalysis.totalGaps, 0, "Should detect gaps in medication")
        XCTAssertGreaterThan(result.qualityMetrics.gapAnalysis.averageGapDays, 0, "Should calculate average gap days")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyMedicationRecords() {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: [],
            medicationFrequency: .daily,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.adherencePercentage, 0.0, "Empty records should result in 0% adherence")
        XCTAssertEqual(result.actualDoses, 0, "Should have 0 actual doses")
        XCTAssertGreaterThan(result.expectedDoses, 0, "Should still have expected doses")
    }
    
    func testAsNeededMedication() {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: [],
            medicationFrequency: .asNeeded,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.expectedDoses, 0, "As needed medications should have 0 expected doses")
        XCTAssertEqual(result.adherencePercentage, 0.0, "As needed medications should have 0% adherence")
    }
    
    func testCustomFrequencyMedication() {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        let result = adherenceCalculator.calculateAdherence(
            medicationRecords: [],
            medicationFrequency: .custom(intervalDays: 3),
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(result.expectedDoses, 10, "Custom 3-day frequency should expect 10 doses in 30 days")
    }
    
    // MARK: - Service Integration Tests
    
    func testMedicationAdherenceService() {
        let expectation = XCTestExpectation(description: "Adherence calculation completed")
        
        Task {
            await medicationAdherenceService.calculateUserAdherence(
                userId: "test_user",
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                endDate: Date()
            )
            
            XCTAssertNotNil(medicationAdherenceService.adherenceResults, "Should have adherence results")
            XCTAssertGreaterThanOrEqual(medicationAdherenceService.overallAdherence, 0, "Should have overall adherence")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
