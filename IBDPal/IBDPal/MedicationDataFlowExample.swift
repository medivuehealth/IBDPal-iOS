import Foundation
import SwiftUI

// MARK: - Medication Data Flow Example
// This file demonstrates how real medication data flows from the database
// to the industry-standard adherence calculation

class MedicationDataFlowExample: ObservableObject {
    
    @Published var dataFlowSteps: [DataFlowStep] = []
    @Published var isProcessing: Bool = false
    
    private let databaseService = MedicationDatabaseService.shared
    @MainActor private let adherenceService = IndustryStandardMedicationAdherenceService()
    
    // MARK: - Complete Data Flow Example
    
    func demonstrateCompleteDataFlow(userId: String, userToken: String) async {
        isProcessing = true
        dataFlowSteps = []
        
        // Step 1: Database Query
        await addStep("1. Database Query", "Fetching journal entries from database...")
        
        do {
            // Step 2: Fetch Real Data
            await addStep("2. Fetch Real Data", "Querying journal_entries table for medication records")
            
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            let endDate = Date()
            
            let medicationRecords = try await databaseService.fetchMedicationRecordsWithAuth(
                userId: userId,
                userToken: userToken,
                startDate: startDate,
                endDate: endDate
            )
            
            await addStep("3. Data Retrieved", "Found \(medicationRecords.count) medication records")
            
            // Step 3: Show Raw Data
            await showRawData(medicationRecords)
            
            // Step 4: Group by Medication
            await addStep("4. Group by Medication", "Organizing records by medication type")
            
            let groupedRecords = Dictionary(grouping: medicationRecords) { $0.medicationName }
            
            for (medicationName, records) in groupedRecords {
                await addStep("5. \(medicationName)", "Found \(records.count) records for \(medicationName)")
            }
            
            // Step 5: Calculate Adherence
            await addStep("6. Calculate Adherence", "Computing industry-standard adherence metrics")
            
            await adherenceService.calculateUserAdherence(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            
            await addStep("7. Adherence Results", "Overall adherence: \(String(format: "%.1f", adherenceService.overallAdherence))%")
            
            // Step 6: Show Detailed Results
            await showDetailedResults(adherenceService.adherenceResults)
            
        } catch {
            await addStep("Error", "Failed to process medication data: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    // MARK: - Database Query Example
    
    func showDatabaseQueryExample() async {
        await addStep("Database Query", """
        SELECT 
            entry_id,
            user_id,
            entry_date,
            medication_taken,
            medication_type,
            created_at
        FROM journal_entries 
        WHERE user_id = $1 
        AND entry_date BETWEEN $2 AND $3 
        AND medication_taken = true
        ORDER BY entry_date ASC
        """)
    }
    
    // MARK: - Data Transformation Example
    
    func showDataTransformationExample() async {
        await addStep("Data Transformation", """
        Journal Entry → Medication Record:
        
        Journal Entry:
        - entry_id: 123
        - user_id: "user_456"
        - entry_date: "2024-01-15"
        - medication_taken: true
        - medication_type: "Mesalamine"
        
        ↓ Transforms to ↓
        
        Medication Record:
        - id: "123_medication"
        - medicationName: "Mesalamine"
        - dateTaken: 2024-01-15 00:00:00
        - dosage: "400mg"
        - notes: "Taken as recorded in journal"
        - userId: "user_456"
        """)
    }
    
    // MARK: - Adherence Calculation Example
    
    func showAdherenceCalculationExample() async {
        await addStep("Adherence Calculation", """
        Example: Mesalamine (Daily Medication)
        
        Date Range: 2024-01-01 to 2024-01-31 (31 days)
        Expected Doses: 31 (daily medication)
        Actual Doses: 28 (from database records)
        
        Adherence = (28 / 31) × 100 = 90.3%
        
        Quality Metrics:
        - Timing Consistency: 85% (consistent morning intake)
        - Gap Analysis: 3 gaps, average 1.2 days
        - Streak Analysis: Current streak 7 days, longest 12 days
        """)
    }
    
    // MARK: - Helper Functions
    
    private func addStep(_ title: String, _ description: String) async {
        await MainActor.run {
            let step = DataFlowStep(
                title: title,
                description: description,
                timestamp: Date()
            )
            dataFlowSteps.append(step)
        }
    }
    
    private func showRawData(_ records: [MedicationIntakeRecord]) async {
        let sampleRecords = Array(records.prefix(5))
        var description = "Sample Records:\n"
        
        for record in sampleRecords {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            let dateString = dateFormatter.string(from: record.dateTaken)
            
            description += "• \(record.medicationName) - \(dateString) - \(record.dosage ?? "N/A")\n"
        }
        
        if records.count > 5 {
            description += "... and \(records.count - 5) more records"
        }
        
        await addStep("Raw Data Sample", description)
    }
    
    private func showDetailedResults(_ results: [String: MedicationAdherenceResult]) async {
        for (medicationName, result) in results {
            await addStep("\(medicationName) Results", """
            Adherence: \(String(format: "%.1f", result.adherencePercentage))%
            Expected: \(result.expectedDoses) doses
            Actual: \(result.actualDoses) doses
            Trend: \(result.trendAnalysis)
            Quality: \(String(format: "%.1f", result.qualityMetrics.timingConsistency))% consistency
            """)
        }
    }
}

// MARK: - Supporting Structures

struct DataFlowStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let timestamp: Date
}

// MARK: - Real Database Integration Example

extension MedicationDataFlowExample {
    
    /// Example of how to integrate with the actual database
    func integrateWithRealDatabase(userId: String, userToken: String) async {
        
        do {
            // 1. Fetch medication records from database
            let _ = try await databaseService.fetchMedicationRecordsWithAuth(
                userId: userId,
                userToken: userToken,
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                endDate: Date()
            )
            
            // 2. Calculate adherence for each medication
            await adherenceService.calculateUserAdherence(
                userId: userId,
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                endDate: Date()
            )
            
            // 3. Get detailed summaries
            let summaries = try await databaseService.getAllMedicationAdherence(
                userId: userId,
                userToken: userToken
            )
            
            // 4. Process results
            for (medicationName, summary) in summaries {
                print("📊 \(medicationName):")
                print("   Adherence: \(String(format: "%.1f", summary.adherencePercentage))%")
                print("   Expected: \(summary.expectedDoses) doses")
                print("   Actual: \(summary.actualDoses) doses")
                print("   Records: \(summary.records.count)")
            }
            
        } catch {
            print("❌ [MedicationDataFlowExample] Error integrating with database: \(error.localizedDescription)")
        }
    }
}

// MARK: - Database Schema Reference

struct DatabaseSchemaReference {
    
    static let journalEntriesTable = """
    CREATE TABLE journal_entries (
        entry_id SERIAL PRIMARY KEY,
        user_id TEXT NOT NULL,
        entry_date DATE NOT NULL,
        medication_taken BOOLEAN DEFAULT FALSE,
        medication_type TEXT DEFAULT 'None',
        -- ... other fields
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    
    static let medicationFields = """
    Key Fields for Medication Tracking:
    - medication_taken: BOOLEAN (true if medication was taken)
    - medication_type: TEXT (name of medication, e.g., "Mesalamine")
    - entry_date: DATE (date when medication was taken)
    - user_id: TEXT (identifies the user)
    """
    
    static let sampleQuery = """
    SELECT 
        entry_id,
        user_id,
        entry_date,
        medication_taken,
        medication_type
    FROM journal_entries 
    WHERE user_id = $1 
    AND entry_date BETWEEN $2 AND $3 
    AND medication_taken = true
    ORDER BY entry_date ASC;
    """
}
