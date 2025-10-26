import Foundation
import SwiftUI

// MARK: - Medication Timeframe Data Example
// Shows exactly what timeframe data is fetched for medication adherence calculation

class MedicationTimeframeExample: ObservableObject {
    
    @Published var timeframeInfo: TimeframeInfo?
    @Published var sampleData: [SampleMedicationRecord] = []
    
    // MARK: - Current Timeframe Configuration
    
    func demonstrateCurrentTimeframe() {
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today
        
        timeframeInfo = TimeframeInfo(
            startDate: threeMonthsAgo,
            endDate: today,
            totalDays: Calendar.current.dateComponents([.day], from: threeMonthsAgo, to: today).day ?? 0,
            totalWeeks: Calendar.current.dateComponents([.weekOfYear], from: threeMonthsAgo, to: today).weekOfYear ?? 0,
            totalMonths: 3
        )
        
        generateSampleData()
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleData() {
        guard let timeframeInfo = timeframeInfo else { return }
        
        let calendar = Calendar.current
        var currentDate = timeframeInfo.startDate
        var records: [SampleMedicationRecord] = []
        
        // Generate sample medication records for the 3-month period
        while currentDate <= timeframeInfo.endDate {
            // Simulate different medication frequencies
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            let dayOfMonth = calendar.component(.day, from: currentDate)
            
            // Daily medications (Mesalamine, Azathioprine)
            if dayOfWeek != 7 { // Skip Sundays for some medications
                records.append(SampleMedicationRecord(
                    date: currentDate,
                    medicationName: "Mesalamine",
                    frequency: "Daily",
                    taken: Double.random(in: 0...1) > 0.1, // 90% adherence
                    dosage: "400mg"
                ))
            }
            
            // Weekly medications (Infliximab) - every 7 days
            if dayOfMonth % 7 == 1 {
                records.append(SampleMedicationRecord(
                    date: currentDate,
                    medicationName: "Infliximab",
                    frequency: "Weekly",
                    taken: Double.random(in: 0...1) > 0.05, // 95% adherence
                    dosage: "5mg/kg"
                ))
            }
            
            // Bi-weekly medications (Adalimumab) - every 14 days
            if dayOfMonth % 14 == 1 {
                records.append(SampleMedicationRecord(
                    date: currentDate,
                    medicationName: "Adalimumab",
                    frequency: "Bi-weekly",
                    taken: Double.random(in: 0...1) > 0.1, // 90% adherence
                    dosage: "40mg"
                ))
            }
            
            // Monthly medications (Vedolizumab) - every 30 days
            if dayOfMonth % 30 == 1 {
                records.append(SampleMedicationRecord(
                    date: currentDate,
                    medicationName: "Vedolizumab",
                    frequency: "Monthly",
                    taken: Double.random(in: 0...1) > 0.05, // 95% adherence
                    dosage: "300mg"
                ))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        sampleData = records.sorted { $0.date < $1.date }
    }
    
    // MARK: - Expected Doses Calculation
    
    func calculateExpectedDoses() -> [String: Int] {
        guard let timeframeInfo = timeframeInfo else { return [:] }
        
        let totalDays = timeframeInfo.totalDays
        
        return [
            "Mesalamine": totalDays, // Daily
            "Infliximab": max(1, totalDays / 7), // Weekly
            "Adalimumab": max(1, totalDays / 14), // Bi-weekly
            "Vedolizumab": max(1, totalDays / 30) // Monthly
        ]
    }
    
    // MARK: - Actual Doses Calculation
    
    func calculateActualDoses() -> [String: Int] {
        let groupedRecords = Dictionary(grouping: sampleData) { $0.medicationName }
        
        return groupedRecords.mapValues { records in
            records.filter { $0.taken }.count
        }
    }
    
    // MARK: - Adherence Calculation
    
    func calculateAdherence() -> [String: Double] {
        let expectedDoses = calculateExpectedDoses()
        let actualDoses = calculateActualDoses()
        
        var adherenceResults: [String: Double] = [:]
        for (medicationName, expected) in expectedDoses {
            let actual = actualDoses[medicationName] ?? 0
            adherenceResults[medicationName] = expected > 0 ? (Double(actual) / Double(expected)) * 100.0 : 0.0
        }
        return adherenceResults
    }
    
    // MARK: - Monthly Breakdown
    
    func getMonthlyBreakdown() -> [MonthlyBreakdown] {
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: sampleData) { record in
            calendar.dateInterval(of: .month, for: record.date)!.start
        }
        
        return groupedByMonth.map { (month, records) in
            let medicationGroups = Dictionary(grouping: records) { $0.medicationName }
            
            let medicationData = medicationGroups.mapValues { medicationRecords in
                let expected = getExpectedDosesForMonth(medicationName: medicationRecords.first?.medicationName ?? "", month: month)
                let actual = medicationRecords.filter { $0.taken }.count
                let adherence = expected > 0 ? (Double(actual) / Double(expected)) * 100.0 : 0.0
                
                return MedicationMonthData(
                    expected: expected,
                    actual: actual,
                    adherence: adherence
                )
            }
            
            return MonthlyBreakdown(
                month: month,
                medicationData: medicationData
            )
        }.sorted { $0.month < $1.month }
    }
    
    private func getExpectedDosesForMonth(medicationName: String, month: Date) -> Int {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: month)!
        let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        
        switch medicationName {
        case "Mesalamine":
            return daysInMonth
        case "Infliximab":
            return max(1, daysInMonth / 7)
        case "Adalimumab":
            return max(1, daysInMonth / 14)
        case "Vedolizumab":
            return max(1, daysInMonth / 30)
        default:
            return 0
        }
    }
}

// MARK: - Supporting Data Structures

struct TimeframeInfo {
    let startDate: Date
    let endDate: Date
    let totalDays: Int
    let totalWeeks: Int
    let totalMonths: Int
}

struct SampleMedicationRecord {
    let date: Date
    let medicationName: String
    let frequency: String
    let taken: Bool
    let dosage: String
}

struct MedicationMonthData {
    let expected: Int
    let actual: Int
    let adherence: Double
}

struct MonthlyBreakdown {
    let month: Date
    let medicationData: [String: MedicationMonthData]
}

// MARK: - Current Configuration

extension MedicationTimeframeExample {
    
    /// Shows the exact timeframe configuration used in the app
    func showCurrentConfiguration() -> String {
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return """
        Current Medication Adherence Timeframe:
        
        📅 Start Date: \(dateFormatter.string(from: threeMonthsAgo))
        📅 End Date: \(dateFormatter.string(from: today))
        📊 Total Days: \(Calendar.current.dateComponents([.day], from: threeMonthsAgo, to: today).day ?? 0)
        📊 Total Weeks: \(Calendar.current.dateComponents([.weekOfYear], from: threeMonthsAgo, to: today).weekOfYear ?? 0)
        📊 Total Months: 3
        
        This timeframe provides:
        • Sufficient data for trend analysis
        • Monthly averaging for different medication frequencies
        • Industry-standard adherence calculation
        • Evidence-based target adjustment
        """
    }
    
    /// Shows what data would be fetched for today's date
    func showTodaysDataFetch() -> String {
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return """
        Database Query for Today (\(dateFormatter.string(from: today))):
        
        SELECT 
            entry_id,
            user_id,
            entry_date,
            medication_taken,
            medication_type,
            created_at
        FROM journal_entries 
        WHERE user_id = $1 
        AND entry_date BETWEEN '\(dateFormatter.string(from: threeMonthsAgo))' AND '\(dateFormatter.string(from: today))'
        AND medication_taken = true
        ORDER BY entry_date ASC;
        
        This query fetches:
        • All medication records from \(dateFormatter.string(from: threeMonthsAgo)) to \(dateFormatter.string(from: today))
        • Only records where medication_taken = true
        • Sorted by date for chronological analysis
        • Used for industry-standard adherence calculation
        """
    }
}
