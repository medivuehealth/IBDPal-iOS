import Foundation
import SwiftUI
import Combine

// MARK: - Industry-Standard Medication Adherence Service
// Integrates proper medication adherence calculation with evidence-based targets
// Uses frequency-based intervals and monthly averaging as per industry standards

@MainActor
class IndustryStandardMedicationAdherenceService: ObservableObject {
    
    @Published var adherenceResults: [String: MedicationAdherenceResult] = [:]
    @Published var overallAdherence: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let adherenceCalculator = MedicationAdherenceCalculator.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Interface
    
    /// Calculate medication adherence for a user using industry standards
    func calculateUserAdherence(
        userId: String,
        startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        endDate: Date = Date()
    ) async {
        isLoading = true
        error = nil
        
        do {
            let results = try await adherenceCalculator.calculateMultiMedicationAdherence(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            
            self.adherenceResults = results
            self.overallAdherence = calculateOverallAdherence(from: results)
            
            print("✅ [IndustryStandardMedicationAdherenceService] Adherence calculated successfully")
            print("📊 Overall Adherence: \(String(format: "%.1f", overallAdherence))%")
            print("📊 Medications: \(results.keys.joined(separator: ", "))")
            
        } catch {
            self.error = "Failed to calculate medication adherence: \(error.localizedDescription)"
            print("❌ [IndustryStandardMedicationAdherenceService] Error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Get adherence for a specific medication
    func getAdherenceForMedication(_ medicationName: String) -> MedicationAdherenceResult? {
        return adherenceResults[medicationName]
    }
    
    /// Get overall adherence percentage
    var overallAdherencePercentage: Double {
        return overallAdherence
    }
    
    /// Get adherence trend
    var adherenceTrend: AdherenceTrend {
        guard !adherenceResults.isEmpty else { return .insufficientData }
        
        let allTrends = adherenceResults.values.map { $0.trendAnalysis }
        let improvingCount = allTrends.filter { $0 == .improving }.count
        let decliningCount = allTrends.filter { $0 == .declining }.count
        
        if improvingCount > decliningCount {
            return .improving
        } else if decliningCount > improvingCount {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// Get quality metrics for all medications
    var overallQualityMetrics: AdherenceQualityMetrics? {
        guard !adherenceResults.isEmpty else { return nil }
        
        let allMetrics = adherenceResults.values.map { $0.qualityMetrics }
        
        let averageTimingConsistency = allMetrics.map { $0.timingConsistency }.reduce(0, +) / Double(allMetrics.count)
        let totalGaps = allMetrics.map { $0.gapAnalysis.totalGaps }.reduce(0, +)
        let averageGapDays = allMetrics.map { $0.averageGapDays }.reduce(0, +) / Double(allMetrics.count)
        let longestStreak = allMetrics.map { $0.longestStreak }.max() ?? 0
        let currentStreak = allMetrics.map { $0.currentStreak }.max() ?? 0
        
        return AdherenceQualityMetrics(
            timingConsistency: averageTimingConsistency,
            gapAnalysis: GapAnalysis(
                totalGaps: totalGaps,
                averageGapDays: averageGapDays,
                longestGapDays: allMetrics.map { $0.gapAnalysis.longestGapDays }.max() ?? 0
            ),
            streakAnalysis: StreakAnalysis(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                averageStreak: allMetrics.map { $0.streakAnalysis.averageStreak }.reduce(0, +) / allMetrics.count
            ),
            averageGapDays: averageGapDays,
            longestStreak: longestStreak,
            currentStreak: currentStreak
        )
    }
    
    // MARK: - Evidence-Based Target Integration
    
    /// Get evidence-based targets adjusted for actual medication adherence
    func getEvidenceBasedTargetsAdjustedForAdherence(
        userProfile: MicronutrientProfile,
        baseTargets: MedicationAdherenceTarget
    ) -> MedicationAdherenceTarget {
        
        // Adjust targets based on actual adherence performance
        let adherenceAdjustment = calculateAdherenceAdjustment(
            currentAdherence: overallAdherence,
            targetAdherence: baseTargets.target
        )
        
        return MedicationAdherenceTarget(
            target: max(70.0, min(100.0, baseTargets.target + adherenceAdjustment)),
            warningThreshold: max(60.0, min(95.0, baseTargets.warningThreshold + adherenceAdjustment)),
            criticalThreshold: max(50.0, min(90.0, baseTargets.criticalThreshold + adherenceAdjustment)),
            basedOn: "Industry-standard calculation with evidence-based adjustments"
        )
    }
    
    // MARK: - Monthly Analysis
    
    /// Get monthly adherence breakdown
    func getMonthlyAdherenceBreakdown() -> [MonthlyAdherenceSummary] {
        var monthlySummaries: [MonthlyAdherenceSummary] = []
        
        for (medicationName, result) in adherenceResults {
            for monthlyData in result.monthlyAverages {
                let summary = MonthlyAdherenceSummary(
                    month: monthlyData.month,
                    medicationName: medicationName,
                    adherencePercentage: monthlyData.adherencePercentage,
                    expectedDoses: monthlyData.expectedDoses,
                    actualDoses: monthlyData.actualDoses,
                    frequency: result.medicationFrequency
                )
                monthlySummaries.append(summary)
            }
        }
        
        return monthlySummaries.sorted { $0.month < $1.month }
    }
    
    /// Get adherence trends by month
    func getAdherenceTrendsByMonth() -> [AdherenceTrendData] {
        let monthlyBreakdown = getMonthlyAdherenceBreakdown()
        let groupedByMonth = Dictionary(grouping: monthlyBreakdown) { 
            Calendar.current.dateInterval(of: .month, for: $0.month)!.start 
        }
        
        return groupedByMonth.map { (month, summaries) in
            let averageAdherence = summaries.map { $0.adherencePercentage }.reduce(0, +) / Double(summaries.count)
            let totalExpected = summaries.map { $0.expectedDoses }.reduce(0, +)
            let totalActual = summaries.map { $0.actualDoses }.reduce(0, +)
            
            return AdherenceTrendData(
                month: month,
                averageAdherence: averageAdherence,
                totalExpectedDoses: totalExpected,
                totalActualDoses: totalActual,
                medicationCount: summaries.count
            )
        }.sorted { $0.month < $1.month }
    }
    
    // MARK: - Helper Functions
    
    private func calculateOverallAdherence(from results: [String: MedicationAdherenceResult]) -> Double {
        guard !results.isEmpty else { return 0.0 }
        
        let adherencePercentages = results.values.map { $0.adherencePercentage }
        return adherencePercentages.reduce(0, +) / Double(adherencePercentages.count)
    }
    
    private func calculateAdherenceAdjustment(currentAdherence: Double, targetAdherence: Double) -> Double {
        let difference = currentAdherence - targetAdherence
        
        // If user is performing better than target, slightly increase target
        if difference > 5.0 {
            return 2.0
        }
        // If user is struggling significantly, decrease target for achievability
        else if difference < -10.0 {
            return -5.0
        }
        // Otherwise, keep target the same
        else {
            return 0.0
        }
    }
}

// MARK: - Supporting Data Structures

struct MonthlyAdherenceSummary {
    let month: Date
    let medicationName: String
    let adherencePercentage: Double
    let expectedDoses: Int
    let actualDoses: Int
    let frequency: MedicationFrequency
}

struct AdherenceTrendData {
    let month: Date
    let averageAdherence: Double
    let totalExpectedDoses: Int
    let totalActualDoses: Int
    let medicationCount: Int
}

// MARK: - Database Integration Extension

extension IndustryStandardMedicationAdherenceService {
    
    /// Fetch medication intake records from database with proper filtering
    func fetchMedicationRecordsFromDatabase(
        userId: String,
        medicationNames: [String]? = nil,
        startDate: Date,
        endDate: Date
    ) async throws -> [MedicationIntakeRecord] {
        
        // Use the real database service to fetch actual medication records
        let databaseService = MedicationDatabaseService.shared
        
        if let medicationNames = medicationNames, !medicationNames.isEmpty {
            // Fetch specific medications
            return try await databaseService.fetchMedicationRecords(
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                medicationTypes: medicationNames
            )
        } else {
            // Fetch all medications
            return try await databaseService.fetchMedicationRecords(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
        }
    }
    
    private func generateMockMedicationRecords(
        userId: String,
        medicationNames: [String],
        startDate: Date,
        endDate: Date
    ) -> [MedicationIntakeRecord] {
        
        var records: [MedicationIntakeRecord] = []
        let calendar = Calendar.current
        
        for medicationName in medicationNames {
            // Generate records based on medication frequency
            let frequency = determineMedicationFrequency(medicationName: medicationName)
            let interval = getIntervalForFrequency(frequency)
            
            var currentDate = startDate
            var recordId = 1
            
            while currentDate <= endDate {
                // Add some realistic variation (not every dose taken)
                if Double.random(in: 0...1) > 0.1 { // 90% adherence
                    let record = MedicationIntakeRecord(
                        id: "\(medicationName)_\(recordId)",
                        medicationName: medicationName,
                        dateTaken: currentDate,
                        dosage: getDosageForMedication(medicationName),
                        notes: "Taken as prescribed",
                        userId: userId
                    )
                    records.append(record)
                }
                
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? currentDate
                recordId += 1
            }
        }
        
        return records.sorted { $0.dateTaken < $1.dateTaken }
    }
    
    private func determineMedicationFrequency(medicationName: String) -> MedicationFrequency {
        switch medicationName.lowercased() {
        case "mesalamine", "sulfasalazine":
            return .daily
        case "azathioprine", "mercaptopurine":
            return .daily
        case "infliximab", "adalimumab":
            return .biWeekly
        case "vedolizumab":
            return .monthly
        default:
            return .daily
        }
    }
    
    private func getIntervalForFrequency(_ frequency: MedicationFrequency) -> Int {
        switch frequency {
        case .daily: return 1
        case .twiceDaily: return 1
        case .weekly: return 7
        case .biWeekly: return 14
        case .monthly: return 30
        case .asNeeded: return 1
        case .custom(let days): return days
        }
    }
    
    private func getDosageForMedication(_ medicationName: String) -> String {
        switch medicationName.lowercased() {
        case "mesalamine":
            return "400mg"
        case "azathioprine":
            return "50mg"
        case "infliximab":
            return "5mg/kg"
        case "adalimumab":
            return "40mg"
        case "vedolizumab":
            return "300mg"
        default:
            return "As prescribed"
        }
    }
}
