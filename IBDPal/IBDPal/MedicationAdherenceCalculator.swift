import Foundation
import SwiftUI

// MARK: - Industry-Standard Medication Adherence Calculator
// Calculates adherence based on medication frequency intervals and actual intake records
// Follows industry standards for medication adherence measurement

class MedicationAdherenceCalculator: ObservableObject {
    static let shared = MedicationAdherenceCalculator()
    
    private init() {}
    
    // MARK: - Core Adherence Calculation
    
    /// Calculate medication adherence based on frequency intervals and actual intake records
    /// - Parameters:
    ///   - medicationRecords: Array of medication intake records from database
    ///   - medicationFrequency: Frequency of medication (e.g., "daily", "weekly", "bi-weekly")
    ///   - startDate: Start date for calculation period
    ///   - endDate: End date for calculation period
    /// - Returns: MedicationAdherenceResult with detailed adherence metrics
    func calculateAdherence(
        medicationRecords: [MedicationIntakeRecord],
        medicationFrequency: MedicationFrequency,
        startDate: Date,
        endDate: Date
    ) -> MedicationAdherenceResult {
        
        // Step 1: Calculate expected doses based on frequency
        let expectedDoses = calculateExpectedDoses(
            frequency: medicationFrequency,
            startDate: startDate,
            endDate: endDate
        )
        
        // Step 2: Calculate actual doses taken
        let actualDoses = calculateActualDoses(
            records: medicationRecords,
            startDate: startDate,
            endDate: endDate
        )
        
        // Step 3: Calculate adherence percentage
        let adherencePercentage = calculateAdherencePercentage(
            expected: expectedDoses,
            actual: actualDoses
        )
        
        // Step 4: Calculate monthly averages for different medication types
        let monthlyAverages = calculateMonthlyAverages(
            medicationRecords: medicationRecords,
            medicationFrequency: medicationFrequency,
            startDate: startDate,
            endDate: endDate
        )
        
        // Step 5: Calculate trend analysis
        let trendAnalysis = calculateTrendAnalysis(monthlyAverages: monthlyAverages)
        
        // Step 6: Calculate adherence quality metrics
        let qualityMetrics = calculateQualityMetrics(
            records: medicationRecords,
            expectedDoses: expectedDoses,
            frequency: medicationFrequency
        )
        
        return MedicationAdherenceResult(
            adherencePercentage: adherencePercentage,
            expectedDoses: expectedDoses,
            actualDoses: actualDoses,
            monthlyAverages: monthlyAverages,
            trendAnalysis: trendAnalysis,
            qualityMetrics: qualityMetrics,
            calculationPeriod: DateInterval(start: startDate, end: endDate),
            medicationFrequency: medicationFrequency
        )
    }
    
    // MARK: - Expected Doses Calculation
    
    private func calculateExpectedDoses(
        frequency: MedicationFrequency,
        startDate: Date,
        endDate: Date
    ) -> Int {
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        switch frequency {
        case .daily:
            return daysBetween + 1 // Include both start and end dates
        case .twiceDaily:
            return (daysBetween + 1) * 2
        case .weekly:
            return max(1, (daysBetween + 1) / 7)
        case .biWeekly:
            return max(1, (daysBetween + 1) / 14)
        case .monthly:
            return max(1, (daysBetween + 1) / 30)
        case .asNeeded:
            return 0 // Cannot calculate expected doses for PRN medications
        case .custom(let intervalDays):
            return max(1, (daysBetween + 1) / intervalDays)
        }
    }
    
    // MARK: - Actual Doses Calculation
    
    private func calculateActualDoses(
        records: [MedicationIntakeRecord],
        startDate: Date,
        endDate: Date
    ) -> Int {
        return records.filter { record in
            record.dateTaken >= startDate && record.dateTaken <= endDate
        }.count
    }
    
    // MARK: - Adherence Percentage Calculation
    
    private func calculateAdherencePercentage(expected: Int, actual: Int) -> Double {
        guard expected > 0 else { return 0.0 }
        return min(100.0, (Double(actual) / Double(expected)) * 100.0)
    }
    
    // MARK: - Monthly Averages Calculation
    
    private func calculateMonthlyAverages(
        medicationRecords: [MedicationIntakeRecord],
        medicationFrequency: MedicationFrequency,
        startDate: Date,
        endDate: Date
    ) -> [MonthlyAdherenceData] {
        
        let calendar = Calendar.current
        var monthlyData: [MonthlyAdherenceData] = []
        
        // Group records by month
        let groupedRecords = Dictionary(grouping: medicationRecords) { record in
            calendar.dateInterval(of: .month, for: record.dateTaken)!
        }
        
        // Calculate adherence for each month
        for (monthInterval, records) in groupedRecords {
            let expectedDoses = calculateExpectedDoses(
                frequency: medicationFrequency,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )
            
            let actualDoses = records.count
            let adherencePercentage = calculateAdherencePercentage(
                expected: expectedDoses,
                actual: actualDoses
            )
            
            let monthlyDataPoint = MonthlyAdherenceData(
                month: monthInterval.start,
                expectedDoses: expectedDoses,
                actualDoses: actualDoses,
                adherencePercentage: adherencePercentage,
                records: records
            )
            
            monthlyData.append(monthlyDataPoint)
        }
        
        return monthlyData.sorted { $0.month < $1.month }
    }
    
    // MARK: - Trend Analysis
    
    private func calculateTrendAnalysis(monthlyAverages: [MonthlyAdherenceData]) -> AdherenceTrend {
        guard monthlyAverages.count >= 2 else {
            return AdherenceTrend.insufficientData
        }
        
        let recentMonths = monthlyAverages.suffix(3)
        let olderMonths = monthlyAverages.dropLast(3).suffix(3)
        
        guard !recentMonths.isEmpty && !olderMonths.isEmpty else {
            return AdherenceTrend.insufficientData
        }
        
        let recentAverage = recentMonths.map { $0.adherencePercentage }.reduce(0, +) / Double(recentMonths.count)
        let olderAverage = olderMonths.map { $0.adherencePercentage }.reduce(0, +) / Double(olderMonths.count)
        
        let change = recentAverage - olderAverage
        
        if change > 5.0 {
            return AdherenceTrend.improving
        } else if change < -5.0 {
            return AdherenceTrend.declining
        } else {
            return AdherenceTrend.stable
        }
    }
    
    // MARK: - Quality Metrics
    
    private func calculateQualityMetrics(
        records: [MedicationIntakeRecord],
        expectedDoses: Int,
        frequency: MedicationFrequency
    ) -> AdherenceQualityMetrics {
        
        // Calculate timing consistency
        let timingConsistency = calculateTimingConsistency(records: records, frequency: frequency)
        
        // Calculate gap analysis
        let gapAnalysis = calculateGapAnalysis(records: records, frequency: frequency)
        
        // Calculate streak analysis
        let streakAnalysis = calculateStreakAnalysis(records: records, frequency: frequency)
        
        return AdherenceQualityMetrics(
            timingConsistency: timingConsistency,
            gapAnalysis: gapAnalysis,
            streakAnalysis: streakAnalysis,
            averageGapDays: calculateAverageGapDays(records: records),
            longestStreak: calculateLongestStreak(records: records),
            currentStreak: calculateCurrentStreak(records: records)
        )
    }
    
    private func calculateTimingConsistency(records: [MedicationIntakeRecord], frequency: MedicationFrequency) -> Double {
        guard records.count >= 2 else { return 0.0 }
        
        let sortedRecords = records.sorted { $0.dateTaken < $1.dateTaken }
        var timeDifferences: [TimeInterval] = []
        
        for i in 1..<sortedRecords.count {
            let timeDiff = sortedRecords[i].dateTaken.timeIntervalSince(sortedRecords[i-1].dateTaken)
            timeDifferences.append(timeDiff)
        }
        
        // Calculate standard deviation of time differences
        let average = timeDifferences.reduce(0, +) / Double(timeDifferences.count)
        let variance = timeDifferences.map { pow($0 - average, 2) }.reduce(0, +) / Double(timeDifferences.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to consistency score (0-100)
        let expectedInterval = getExpectedInterval(frequency: frequency)
        let consistencyScore = max(0, 100 - (standardDeviation / expectedInterval) * 100)
        
        return min(100, consistencyScore)
    }
    
    private func getExpectedInterval(frequency: MedicationFrequency) -> TimeInterval {
        switch frequency {
        case .daily:
            return 24 * 60 * 60 // 24 hours
        case .twiceDaily:
            return 12 * 60 * 60 // 12 hours
        case .weekly:
            return 7 * 24 * 60 * 60 // 7 days
        case .biWeekly:
            return 14 * 24 * 60 * 60 // 14 days
        case .monthly:
            return 30 * 24 * 60 * 60 // 30 days
        case .asNeeded:
            return 0
        case .custom(let days):
            return Double(days) * 24 * 60 * 60
        }
    }
    
    private func calculateGapAnalysis(records: [MedicationIntakeRecord], frequency: MedicationFrequency) -> GapAnalysis {
        let sortedRecords = records.sorted { $0.dateTaken < $1.dateTaken }
        let expectedInterval = getExpectedInterval(frequency: frequency)
        
        var gaps: [TimeInterval] = []
        
        for i in 1..<sortedRecords.count {
            let gap = sortedRecords[i].dateTaken.timeIntervalSince(sortedRecords[i-1].dateTaken)
            if gap > expectedInterval * 1.5 { // Gap is significantly longer than expected
                gaps.append(gap)
            }
        }
        
        return GapAnalysis(
            totalGaps: gaps.count,
            averageGapDays: gaps.isEmpty ? 0 : gaps.reduce(0, +) / Double(gaps.count) / (24 * 60 * 60),
            longestGapDays: gaps.isEmpty ? 0 : gaps.max()! / (24 * 60 * 60)
        )
    }
    
    private func calculateStreakAnalysis(records: [MedicationIntakeRecord], frequency: MedicationFrequency) -> StreakAnalysis {
        let sortedRecords = records.sorted { $0.dateTaken < $1.dateTaken }
        let expectedInterval = getExpectedInterval(frequency: frequency)
        
        var currentStreak = 0
        var longestStreak = 0
        var streaks: [Int] = []
        
        for i in 1..<sortedRecords.count {
            let gap = sortedRecords[i].dateTaken.timeIntervalSince(sortedRecords[i-1].dateTaken)
            
            if gap <= expectedInterval * 1.2 { // Within acceptable range
                currentStreak += 1
            } else {
                streaks.append(currentStreak)
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 0
            }
        }
        
        longestStreak = max(longestStreak, currentStreak)
        
        return StreakAnalysis(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageStreak: streaks.isEmpty ? 0 : streaks.reduce(0, +) / streaks.count
        )
    }
    
    private func calculateAverageGapDays(records: [MedicationIntakeRecord]) -> Double {
        guard records.count >= 2 else { return 0.0 }
        
        let sortedRecords = records.sorted { $0.dateTaken < $1.dateTaken }
        var totalGapDays = 0.0
        
        for i in 1..<sortedRecords.count {
            let gapDays = sortedRecords[i].dateTaken.timeIntervalSince(sortedRecords[i-1].dateTaken) / (24 * 60 * 60)
            totalGapDays += gapDays
        }
        
        return totalGapDays / Double(sortedRecords.count - 1)
    }
    
    private func calculateLongestStreak(records: [MedicationIntakeRecord]) -> Int {
        // Implementation for longest streak calculation
        return 0 // Placeholder
    }
    
    private func calculateCurrentStreak(records: [MedicationIntakeRecord]) -> Int {
        // Implementation for current streak calculation
        return 0 // Placeholder
    }
}

// MARK: - Supporting Data Structures

struct MedicationIntakeRecord: Codable, Identifiable {
    let id: String
    let medicationName: String
    let dateTaken: Date
    let dosage: String?
    let notes: String?
    let userId: String
}

enum MedicationFrequency: Codable {
    case daily
    case twiceDaily
    case weekly
    case biWeekly
    case monthly
    case asNeeded
    case custom(intervalDays: Int)
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .twiceDaily: return "Twice Daily"
        case .weekly: return "Weekly"
        case .biWeekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .asNeeded: return "As Needed"
        case .custom(let days): return "Every \(days) days"
        }
    }
}

struct MedicationAdherenceResult {
    let adherencePercentage: Double
    let expectedDoses: Int
    let actualDoses: Int
    let monthlyAverages: [MonthlyAdherenceData]
    let trendAnalysis: AdherenceTrend
    let qualityMetrics: AdherenceQualityMetrics
    let calculationPeriod: DateInterval
    let medicationFrequency: MedicationFrequency
}

struct MonthlyAdherenceData {
    let month: Date
    let expectedDoses: Int
    let actualDoses: Int
    let adherencePercentage: Double
    let records: [MedicationIntakeRecord]
}

enum AdherenceTrend {
    case improving
    case stable
    case declining
    case insufficientData
}

struct AdherenceQualityMetrics {
    let timingConsistency: Double // 0-100
    let gapAnalysis: GapAnalysis
    let streakAnalysis: StreakAnalysis
    let averageGapDays: Double
    let longestStreak: Int
    let currentStreak: Int
}

struct GapAnalysis {
    let totalGaps: Int
    let averageGapDays: Double
    let longestGapDays: Double
}

struct StreakAnalysis {
    let currentStreak: Int
    let longestStreak: Int
    let averageStreak: Int
}

// MARK: - Database Integration

extension MedicationAdherenceCalculator {
    
    /// Fetch medication intake records from database
    func fetchMedicationRecords(
        userId: String,
        medicationName: String? = nil,
        startDate: Date,
        endDate: Date
    ) async throws -> [MedicationIntakeRecord] {
        
        // This would make an API call to fetch records from the database
        // For now, return mock data
        return [
            MedicationIntakeRecord(
                id: "1",
                medicationName: "Mesalamine",
                dateTaken: Date(),
                dosage: "400mg",
                notes: "Taken with breakfast",
                userId: userId
            )
        ]
    }
    
    /// Calculate adherence for multiple medications
    func calculateMultiMedicationAdherence(
        userId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [String: MedicationAdherenceResult] {
        
        // Fetch all medication records for the user
        let allRecords = try await fetchMedicationRecords(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
        
        // Group by medication name
        let groupedRecords = Dictionary(grouping: allRecords) { $0.medicationName }
        
        var results: [String: MedicationAdherenceResult] = [:]
        
        for (medicationName, records) in groupedRecords {
            // Determine frequency based on medication type or user settings
            let frequency = determineMedicationFrequency(medicationName: medicationName)
            
            let adherenceResult = calculateAdherence(
                medicationRecords: records,
                medicationFrequency: frequency,
                startDate: startDate,
                endDate: endDate
            )
            
            results[medicationName] = adherenceResult
        }
        
        return results
    }
    
    private func determineMedicationFrequency(medicationName: String) -> MedicationFrequency {
        // This would typically be stored in the database or user settings
        // For now, return default frequencies based on common medication types
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
}
