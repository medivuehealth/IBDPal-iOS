import Foundation
import SwiftUI

// MARK: - Medication API Usage Example
// Shows how to use the existing server route to fetch 3 months of medication data

class MedicationAPIUsage: ObservableObject {
    
    @Published var medicationData: [MedicationIntakeRecord] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Using Existing Server Route
    
    /// Fetch 3 months of medication data using the existing API
    func fetchThreeMonthsMedicationData(
        userEmail: String,
        userToken: String
    ) async {
        isLoading = true
        error = nil
        
        do {
            // Calculate date range (3 months ago to today)
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
            
            // Format dates for API
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            // Use existing API endpoint
            let medicationRecords = try await fetchMedicationRecordsFromAPI(
                userEmail: userEmail,
                userToken: userToken,
                startDate: startDateString,
                endDate: endDateString
            )
            
            await MainActor.run {
                self.medicationData = medicationRecords
                self.isLoading = false
            }
            
            print("✅ [MedicationAPIUsage] Fetched \(medicationRecords.count) medication records")
            
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch medication data: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ [MedicationAPIUsage] Error: \(error)")
        }
    }
    
    // MARK: - API Integration
    
    private func fetchMedicationRecordsFromAPI(
        userEmail: String,
        userToken: String,
        startDate: String,
        endDate: String
    ) async throws -> [MedicationIntakeRecord] {
        
        // Build API endpoint using existing route
        let endpoint = "\(AppConfig.apiBaseURL)/journal/entries/\(userEmail)?startDate=\(startDate)&endDate=\(endDate)"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        // Create request with authentication
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP Error", code: -1, userInfo: nil)
        }
        
        // Parse journal entries
        let journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
        
        // Convert to medication records
        return convertJournalEntriesToMedicationRecords(journalEntries: journalEntries)
    }
    
    // MARK: - Data Conversion
    
    private func convertJournalEntriesToMedicationRecords(
        journalEntries: [JournalEntry]
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
                    userId: entry.user_id
                )
                
                medicationRecords.append(record)
            }
        }
        
        return medicationRecords.sorted { $0.dateTaken < $1.dateTaken }
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

// MARK: - API Endpoint Documentation

struct MedicationAPIEndpoint {
    
    static let baseURL = "\(AppConfig.apiBaseURL)/journal/entries"
    
    /// Get journal entries for a user with date range filtering
    /// - Parameters:
    ///   - userEmail: User's email address
    ///   - startDate: Start date in YYYY-MM-DD format
    ///   - endDate: End date in YYYY-MM-DD format
    /// - Returns: Array of journal entries
    static func getJournalEntries(
        userEmail: String,
        startDate: String,
        endDate: String
    ) -> String {
        return "\(baseURL)/\(userEmail)?startDate=\(startDate)&endDate=\(endDate)"
    }
    
    /// Example usage
    static func exampleUsage() -> String {
        let userEmail = "user@example.com"
        let startDate = "2024-09-01"
        let endDate = "2024-12-01"
        
        return """
        GET \(getJournalEntries(userEmail: userEmail, startDate: startDate, endDate: endDate))
        
        Headers:
        - Authorization: Bearer {userToken}
        - Content-Type: application/json
        
        Response:
        [
          {
            "entry_id": 123,
            "user_id": "user_456",
            "entry_date": "2024-09-15",
            "medication_taken": true,
            "medication_type": "Mesalamine",
            "created_at": "2024-09-15T08:30:00Z"
          }
        ]
        """
    }
}

// MARK: - Server Route Analysis

struct ServerRouteAnalysis {
    
    /// Analyze the existing server route
    static func analyzeExistingRoute() -> String {
        return """
        ✅ EXISTING SERVER ROUTE FOUND!
        
        Route: GET /api/journal/entries/:username
        Parameters:
        - username: User's email address
        - startDate: Start date in YYYY-MM-DD format (optional)
        - endDate: End date in YYYY-MM-DD format (optional)
        
        Database Query:
        SELECT je.* FROM journal_entries je
        JOIN users u ON je.user_id = u.user_id
        WHERE u.email = $1 
        AND je.entry_date >= $2 
        AND je.entry_date <= $3
        AND (je.notes IS NULL OR je.notes = '' OR je.notes != 'Generated entry with 7 symptoms')
        ORDER BY je.entry_date ASC, je.created_at ASC
        
        Features:
        ✅ Date range filtering (startDate, endDate)
        ✅ User authentication via email
        ✅ Filters out auto-generated entries
        ✅ Returns all journal entry fields including medication data
        ✅ Ordered by date for chronological analysis
        
        This route is PERFECT for medication adherence calculation!
        """
    }
    
    /// Show how to use the route for medication data
    static func showUsageExample() -> String {
        return """
        📊 MEDICATION DATA FETCHING EXAMPLE
        
        // 1. Calculate date range (3 months ago to today)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        
        // 2. Format dates for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // 3. Build API endpoint
        let endpoint = "\(AppConfig.apiBaseURL)/journal/entries/{userEmail}?startDate={startDateString}&endDate={endDateString}"
        
        // 4. Make API call
        // let (data, response) = try await URLSession.shared.data(for: request)
        
        // 5. Parse journal entries
        // let journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
        
        // 6. Filter for medication records
        // let medicationRecords = journalEntries.filter { $0.medication_taken == true }
        
        // 7. Calculate adherence
        // let adherence = calculateAdherence(records: medicationRecords)
        """
    }
}

// MARK: - Integration with Existing Code

extension MedicationAPIUsage {
    
    /// Integrate with the existing IndustryStandardMedicationAdherenceService
    func integrateWithAdherenceService(
        userEmail: String,
        userToken: String
    ) async {
        
        // Fetch 3 months of data
        await fetchThreeMonthsMedicationData(
            userEmail: userEmail,
            userToken: userToken
        )
        
        // Use the medication data for adherence calculation
        let adherenceService = await MainActor.run { IndustryStandardMedicationAdherenceService() }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        
        await adherenceService.calculateUserAdherence(
            userId: userEmail, // Using email as user ID
            startDate: startDate,
            endDate: endDate
        )
        
        print("✅ [MedicationAPIUsage] Integrated with adherence service")
        await MainActor.run {
            print("📊 Overall Adherence: \(String(format: "%.1f", adherenceService.overallAdherence))%")
            print("📊 Medications: \(adherenceService.adherenceResults.keys.joined(separator: ", "))")
        }
    }
}
