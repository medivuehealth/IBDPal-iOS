import Foundation
import SwiftUI

// MARK: - Medication Database Service
// Fetches real medication data from the existing database schema
// Uses the journal_entries table with medication_taken and medication_type fields

class MedicationDatabaseService: ObservableObject {
    static let shared = MedicationDatabaseService()
    
    @Published var medicationRecords: [MedicationIntakeRecord] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - Database Integration
    
    /// Fetch medication intake records from the actual database
    func fetchMedicationRecords(
        userId: String,
        startDate: Date,
        endDate: Date,
        medicationTypes: [String]? = nil
    ) async throws -> [MedicationIntakeRecord] {
        
        isLoading = true
        error = nil
        
        do {
            // Format dates for API call
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            // Build API endpoint
            var endpoint = "\(AppConfig.apiBaseURL)/journal/entries/\(userId)?startDate=\(startDateString)&endDate=\(endDateString)"
            
            if let medicationTypes = medicationTypes, !medicationTypes.isEmpty {
                let typesParam = medicationTypes.joined(separator: ",")
                endpoint += "&medicationTypes=\(typesParam)"
            }
            
            guard let url = URL(string: endpoint) else {
                throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            }
            
            // Make API call
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "HTTP Error", code: -1, userInfo: nil)
            }
            
            // Parse journal entries
            let journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
            
            // Convert journal entries to medication records
            let medicationRecords = convertJournalEntriesToMedicationRecords(
                journalEntries: journalEntries,
                userId: userId
            )
            
            await MainActor.run {
                self.medicationRecords = medicationRecords
                self.isLoading = false
            }
            
            return medicationRecords
            
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch medication records: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    /// Fetch medication records for multiple medications
    func fetchMultiMedicationRecords(
        userId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [String: [MedicationIntakeRecord]] {
        
        // Get all journal entries for the date range
        let allRecords = try await fetchMedicationRecords(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
        
        // Group by medication type
        let groupedRecords = Dictionary(grouping: allRecords) { $0.medicationName }
        
        return groupedRecords
    }
    
    /// Get medication adherence summary for a specific medication
    func getMedicationAdherenceSummary(
        userId: String,
        medicationName: String,
        startDate: Date,
        endDate: Date
    ) async throws -> MedicationAdherenceSummary {
        
        let records = try await fetchMedicationRecords(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            medicationTypes: [medicationName]
        )
        
        let filteredRecords = records.filter { $0.medicationName == medicationName }
        
        // Calculate adherence metrics
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let expectedDoses = calculateExpectedDoses(
            medicationName: medicationName,
            totalDays: totalDays
        )
        let actualDoses = filteredRecords.count
        let adherencePercentage = expectedDoses > 0 ? (Double(actualDoses) / Double(expectedDoses)) * 100.0 : 0.0
        
        return MedicationAdherenceSummary(
            medicationName: medicationName,
            totalDays: totalDays,
            expectedDoses: expectedDoses,
            actualDoses: actualDoses,
            adherencePercentage: adherencePercentage,
            records: filteredRecords
        )
    }
    
    // MARK: - Helper Functions
    
    private func convertJournalEntriesToMedicationRecords(
        journalEntries: [JournalEntry],
        userId: String
    ) -> [MedicationIntakeRecord] {
        
        var medicationRecords: [MedicationIntakeRecord] = []
        
        for entry in journalEntries {
            // Only include entries where medication was taken
            if entry.medication_taken == true {
                let medicationName = entry.medication_type ?? "Unknown"
                
                // Parse entry date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let entryDate = dateFormatter.date(from: entry.entry_date) ?? Date()
                
                // Create medication record
                let record = MedicationIntakeRecord(
                    id: "\(entry.entry_id)_medication",
                    medicationName: medicationName,
                    dateTaken: entryDate,
                    dosage: getDosageForMedication(medicationName),
                    notes: "Taken as recorded in journal",
                    userId: userId
                )
                
                medicationRecords.append(record)
            }
        }
        
        return medicationRecords.sorted { $0.dateTaken < $1.dateTaken }
    }
    
    private func calculateExpectedDoses(medicationName: String, totalDays: Int) -> Int {
        let frequency = determineMedicationFrequency(medicationName: medicationName)
        
        switch frequency {
        case .daily:
            return totalDays
        case .twiceDaily:
            return totalDays * 2
        case .weekly:
            return max(1, totalDays / 7)
        case .biWeekly:
            return max(1, totalDays / 14)
        case .monthly:
            return max(1, totalDays / 30)
        case .asNeeded:
            return 0
        case .custom(let intervalDays):
            return max(1, totalDays / intervalDays)
        }
    }
    
    private func determineMedicationFrequency(medicationName: String) -> MedicationFrequency {
        switch medicationName.lowercased() {
        case "mesalamine", "sulfasalazine", "pentasa", "lialda":
            return .daily
        case "azathioprine", "mercaptopurine", "imuran", "6-mp":
            return .daily
        case "methotrexate", "mtx":
            return .weekly
        case "infliximab", "remicade":
            return .biWeekly
        case "adalimumab", "humira":
            return .biWeekly
        case "vedolizumab", "entyvio":
            return .monthly
        case "ustekinumab", "stelara":
            return .monthly
        case "prednisone", "prednisolone":
            return .daily
        case "budesonide", "entocort":
            return .daily
        default:
            return .daily // Default to daily for unknown medications
        }
    }
    
    private func getDosageForMedication(_ medicationName: String) -> String {
        switch medicationName.lowercased() {
        case "mesalamine":
            return "400mg"
        case "sulfasalazine":
            return "500mg"
        case "azathioprine":
            return "50mg"
        case "mercaptopurine":
            return "50mg"
        case "methotrexate":
            return "15mg"
        case "infliximab":
            return "5mg/kg"
        case "adalimumab":
            return "40mg"
        case "vedolizumab":
            return "300mg"
        case "ustekinumab":
            return "90mg"
        case "prednisone":
            return "20mg"
        case "budesonide":
            return "3mg"
        default:
            return "As prescribed"
        }
    }
}

// MARK: - Supporting Data Structures

struct MedicationAdherenceSummary {
    let medicationName: String
    let totalDays: Int
    let expectedDoses: Int
    let actualDoses: Int
    let adherencePercentage: Double
    let records: [MedicationIntakeRecord]
}

// MARK: - API Integration

extension MedicationDatabaseService {
    
    /// Fetch medication records with authentication
    func fetchMedicationRecordsWithAuth(
        userId: String,
        userToken: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [MedicationIntakeRecord] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/journal/entries/\(userId)?startDate=\(startDateString)&endDate=\(endDateString)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP Error", code: -1, userInfo: nil)
        }
        
        let journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
        return convertJournalEntriesToMedicationRecords(
            journalEntries: journalEntries,
            userId: userId
        )
    }
    
    /// Get medication adherence for all user medications
    func getAllMedicationAdherence(
        userId: String,
        userToken: String,
        startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        endDate: Date = Date()
    ) async throws -> [String: MedicationAdherenceSummary] {
        
        let records = try await fetchMedicationRecordsWithAuth(
            userId: userId,
            userToken: userToken,
            startDate: startDate,
            endDate: endDate
        )
        
        // Group by medication name
        let groupedRecords = Dictionary(grouping: records) { $0.medicationName }
        
        var summaries: [String: MedicationAdherenceSummary] = [:]
        
        for (medicationName, medicationRecords) in groupedRecords {
            let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            let expectedDoses = calculateExpectedDoses(
                medicationName: medicationName,
                totalDays: totalDays
            )
            let actualDoses = medicationRecords.count
            let adherencePercentage = expectedDoses > 0 ? (Double(actualDoses) / Double(expectedDoses)) * 100.0 : 0.0
            
            let summary = MedicationAdherenceSummary(
                medicationName: medicationName,
                totalDays: totalDays,
                expectedDoses: expectedDoses,
                actualDoses: actualDoses,
                adherencePercentage: adherencePercentage,
                records: medicationRecords
            )
            
            summaries[medicationName] = summary
        }
        
        return summaries
    }
}
