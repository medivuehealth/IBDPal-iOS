import XCTest
@testable import IBDPal

// MARK: - Evidence-Based Targets Test Suite
// Comprehensive testing for evidence-based medical adherence and symptom targets

class EvidenceBasedTargetsTests: XCTestCase {
    
    var evidenceBasedTargets: EvidenceBasedTargets.Type!
    var sampleUserProfile: MicronutrientProfile!
    
    override func setUp() {
        super.setUp()
        evidenceBasedTargets = EvidenceBasedTargets.self
        
        // Create sample user profile for testing
        sampleUserProfile = MicronutrientProfile(
            userId: "test_user_123",
            age: 35,
            weight: 70.0,
            height: 165.0,
            gender: "Female",
            diseaseActivity: .remission,
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
    }
    
    override func tearDown() {
        evidenceBasedTargets = nil
        sampleUserProfile = nil
        super.tearDown()
    }
    
    // MARK: - Medication Adherence Target Tests
    
    func testMedicationAdherenceTarget_Remission() {
        let target = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
            for: sampleUserProfile,
            diseaseActivity: .remission,
            medicationHistory: []
        )
        
        XCTAssertEqual(target.target, 90.0, accuracy: 0.1, "Remission target should be 90%")
        XCTAssertEqual(target.warningThreshold, 80.0, accuracy: 0.1, "Warning threshold should be 80%")
        XCTAssertEqual(target.criticalThreshold, 70.0, accuracy: 0.1, "Critical threshold should be 70%")
    }
    
    func testMedicationAdherenceTarget_MildActivity() {
        let target = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
            for: sampleUserProfile,
            diseaseActivity: .mild,
            medicationHistory: []
        )
        
        XCTAssertEqual(target.target, 95.0, accuracy: 0.1, "Mild activity target should be 95%")
        XCTAssertEqual(target.warningThreshold, 85.0, accuracy: 0.1, "Warning threshold should be 85%")
        XCTAssertEqual(target.criticalThreshold, 75.0, accuracy: 0.1, "Critical threshold should be 75%")
    }
    
    func testMedicationAdherenceTarget_ModerateActivity() {
        let target = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
            for: sampleUserProfile,
            diseaseActivity: .moderate,
            medicationHistory: []
        )
        
        XCTAssertEqual(target.target, 98.0, accuracy: 0.1, "Moderate activity target should be 98%")
        XCTAssertEqual(target.warningThreshold, 90.0, accuracy: 0.1, "Warning threshold should be 90%")
        XCTAssertEqual(target.criticalThreshold, 80.0, accuracy: 0.1, "Critical threshold should be 80%")
    }
    
    func testMedicationAdherenceTarget_SevereActivity() {
        let target = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
            for: sampleUserProfile,
            diseaseActivity: .severe,
            medicationHistory: []
        )
        
        XCTAssertEqual(target.target, 100.0, accuracy: 0.1, "Severe activity target should be 100%")
        XCTAssertEqual(target.warningThreshold, 95.0, accuracy: 0.1, "Warning threshold should be 95%")
        XCTAssertEqual(target.criticalThreshold, 90.0, accuracy: 0.1, "Critical threshold should be 90%")
    }
    
    // MARK: - Symptom Target Tests
    
    func testSymptomTargets_Remission() {
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: sampleUserProfile,
            diseaseActivity: .remission,
            symptomHistory: []
        )
        
        XCTAssertEqual(targets.painTarget, 2, "Remission pain target should be 2/10")
        XCTAssertEqual(targets.stressTarget, 3, "Remission stress target should be 3/10")
        XCTAssertEqual(targets.fatigueTarget, 2, "Remission fatigue target should be 2/10")
        XCTAssertEqual(targets.bowelFrequencyTarget, 1, "Remission bowel frequency target should be 1/day")
        XCTAssertEqual(targets.urgencyTarget, 2, "Remission urgency target should be 2/10")
    }
    
    func testSymptomTargets_MildActivity() {
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: sampleUserProfile,
            diseaseActivity: .mild,
            symptomHistory: []
        )
        
        XCTAssertEqual(targets.painTarget, 3, "Mild activity pain target should be 3/10")
        XCTAssertEqual(targets.stressTarget, 4, "Mild activity stress target should be 4/10")
        XCTAssertEqual(targets.fatigueTarget, 3, "Mild activity fatigue target should be 3/10")
        XCTAssertEqual(targets.bowelFrequencyTarget, 2, "Mild activity bowel frequency target should be 2/day")
        XCTAssertEqual(targets.urgencyTarget, 3, "Mild activity urgency target should be 3/10")
    }
    
    func testSymptomTargets_ModerateActivity() {
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: sampleUserProfile,
            diseaseActivity: .moderate,
            symptomHistory: []
        )
        
        XCTAssertEqual(targets.painTarget, 4, "Moderate activity pain target should be 4/10")
        XCTAssertEqual(targets.stressTarget, 5, "Moderate activity stress target should be 5/10")
        XCTAssertEqual(targets.fatigueTarget, 4, "Moderate activity fatigue target should be 4/10")
        XCTAssertEqual(targets.bowelFrequencyTarget, 3, "Moderate activity bowel frequency target should be 3/day")
        XCTAssertEqual(targets.urgencyTarget, 4, "Moderate activity urgency target should be 4/10")
    }
    
    func testSymptomTargets_SevereActivity() {
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: sampleUserProfile,
            diseaseActivity: .severe,
            symptomHistory: []
        )
        
        XCTAssertEqual(targets.painTarget, 5, "Severe activity pain target should be 5/10")
        XCTAssertEqual(targets.stressTarget, 6, "Severe activity stress target should be 6/10")
        XCTAssertEqual(targets.fatigueTarget, 5, "Severe activity fatigue target should be 5/10")
        XCTAssertEqual(targets.bowelFrequencyTarget, 4, "Severe activity bowel frequency target should be 4/day")
        XCTAssertEqual(targets.urgencyTarget, 5, "Severe activity urgency target should be 5/10")
    }
    
    // MARK: - Health Metric Target Tests
    
    func testHealthMetricTargets_Remission() {
        let targets = EvidenceBasedTargets.calculateHealthMetricTargets(
            for: sampleUserProfile,
            diseaseActivity: .remission,
            medicationHistory: [],
            symptomHistory: [],
            healthHistory: []
        )
        
        XCTAssertEqual(targets.medicationAdherenceTarget, 90.0, accuracy: 0.1, "Remission medication adherence target should be 90%")
        XCTAssertEqual(targets.bowelFrequencyTarget, 1.0, accuracy: 0.1, "Remission bowel frequency target should be 1/day")
        XCTAssertEqual(targets.painTarget, 2.0, accuracy: 0.1, "Remission pain target should be 2/10")
        XCTAssertEqual(targets.urgencyTarget, 2.0, accuracy: 0.1, "Remission urgency target should be 2/10")
        XCTAssertEqual(targets.weightChangeTarget, 0.0, accuracy: 0.1, "Remission weight change target should be 0 kg")
    }
    
    func testHealthMetricTargets_MildActivity() {
        let targets = EvidenceBasedTargets.calculateHealthMetricTargets(
            for: sampleUserProfile,
            diseaseActivity: .mild,
            medicationHistory: [],
            symptomHistory: [],
            healthHistory: []
        )
        
        XCTAssertEqual(targets.medicationAdherenceTarget, 95.0, accuracy: 0.1, "Mild activity medication adherence target should be 95%")
        XCTAssertEqual(targets.bowelFrequencyTarget, 2.0, accuracy: 0.1, "Mild activity bowel frequency target should be 2/day")
        XCTAssertEqual(targets.painTarget, 3.0, accuracy: 0.1, "Mild activity pain target should be 3/10")
        XCTAssertEqual(targets.urgencyTarget, 3.0, accuracy: 0.1, "Mild activity urgency target should be 3/10")
        XCTAssertEqual(targets.weightChangeTarget, 0.0, accuracy: 0.1, "Mild activity weight change target should be 0 kg")
    }
    
    // MARK: - Research Sources Tests
    
    func testResearchSources() {
        let sources = EvidenceBasedTargets.getResearchSources()
        
        XCTAssertTrue(sources.contains("American Gastroenterological Association (AGA) 2024 Guidelines"), "Should contain AGA 2024 Guidelines")
        XCTAssertTrue(sources.contains("Crohn's & Colitis Foundation"), "Should contain CCF")
        XCTAssertTrue(sources.contains("World Health Organization (WHO)"), "Should contain WHO")
        XCTAssertTrue(sources.contains("American College of Gastroenterology"), "Should contain ACG")
        XCTAssertTrue(sources.contains("NIH Office of Dietary Supplements"), "Should contain NIH")
    }
    
    // MARK: - Edge Case Tests
    
    func testEdgeCase_YoungPatient() {
        let youngProfile = MicronutrientProfile(
            userId: "young_user",
            age: 16,
            weight: 60.0,
            height: 160.0,
            gender: "Female",
            diseaseActivity: .remission,
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
        
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: youngProfile,
            diseaseActivity: .remission,
            symptomHistory: []
        )
        
        // Young patients should have similar targets but may need adjustments
        XCTAssertEqual(targets.painTarget, 2, "Young patient pain target should be 2/10")
        XCTAssertEqual(targets.stressTarget, 3, "Young patient stress target should be 3/10")
    }
    
    func testEdgeCase_ElderlyPatient() {
        let elderlyProfile = MicronutrientProfile(
            userId: "elderly_user",
            age: 75,
            weight: 65.0,
            height: 155.0,
            gender: "Male",
            diseaseActivity: .remission,
            diseaseType: "IBD",
            medications: [],
            labResults: [],
            supplements: []
        )
        
        let targets = EvidenceBasedTargets.calculateSymptomTargets(
            for: elderlyProfile,
            diseaseActivity: .remission,
            symptomHistory: []
        )
        
        // Elderly patients should have similar targets but may need adjustments
        XCTAssertEqual(targets.painTarget, 2, "Elderly patient pain target should be 2/10")
        XCTAssertEqual(targets.stressTarget, 3, "Elderly patient stress target should be 3/10")
    }
    
    func testEdgeCase_NoMedicationHistory() {
        let targets = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
            for: sampleUserProfile,
            diseaseActivity: .remission,
            medicationHistory: []
        )
        
        // Should still provide targets even with no history
        XCTAssertEqual(targets.target, 90.0, accuracy: 0.1, "Should provide default targets")
        XCTAssertEqual(targets.warningThreshold, 80.0, accuracy: 0.1, "Should provide default warning threshold")
        XCTAssertEqual(targets.criticalThreshold, 70.0, accuracy: 0.1, "Should provide default critical threshold")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_CalculateAllTargets() {
        measure {
            let _ = EvidenceBasedTargets.calculateAllTargets(
                for: sampleUserProfile,
                medicationHistory: [],
                symptomHistory: [],
                healthHistory: []
            )
        }
    }
    
    func testPerformance_CalculateMedicationAdherenceTarget() {
        measure {
            let _ = EvidenceBasedTargets.calculateMedicationAdherenceTarget(
                for: sampleUserProfile,
                diseaseActivity: .remission,
                medicationHistory: []
            )
        }
    }
    
    func testPerformance_CalculateSymptomTargets() {
        measure {
            let _ = EvidenceBasedTargets.calculateSymptomTargets(
                for: sampleUserProfile,
                diseaseActivity: .remission,
                symptomHistory: []
            )
        }
    }
}
