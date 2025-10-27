# Real Medication Data Flow Implementation

## Overview
This document explains how the IBDPal app fetches and processes **real medication data** from the existing database to calculate industry-standard medication adherence.

## Data Flow Architecture

### 1. Database Source
The medication data comes from the existing `journal_entries` table in your PostgreSQL database:

```sql
-- Key fields for medication tracking
CREATE TABLE journal_entries (
    entry_id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    entry_date DATE NOT NULL,
    medication_taken BOOLEAN DEFAULT FALSE,
    medication_type TEXT DEFAULT 'None',
    -- ... other fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Data Flow Steps

#### Step 1: Database Query
```sql
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
ORDER BY entry_date ASC;
```

#### Step 2: API Integration
```swift
// Fetch medication records from database
let medicationRecords = try await databaseService.fetchMedicationRecordsWithAuth(
    userId: userId,
    userToken: userToken,
    startDate: startDate,
    endDate: endDate
)
```

#### Step 3: Data Transformation
```swift
// Convert journal entries to medication records
private func convertJournalEntriesToMedicationRecords(
    journalEntries: [JournalEntry],
    userId: String
) -> [MedicationIntakeRecord] {
    
    var medicationRecords: [MedicationIntakeRecord] = []
    
    for entry in journalEntries {
        if entry.medication_taken == true {
            let record = MedicationIntakeRecord(
                id: "\(entry.entry_id)_medication",
                medicationName: entry.medication_type ?? "Unknown",
                dateTaken: entry.entry_date,
                dosage: getDosageForMedication(entry.medication_type),
                notes: "Taken as recorded in journal",
                userId: userId
            )
            medicationRecords.append(record)
        }
    }
    
    return medicationRecords
}
```

#### Step 4: Adherence Calculation
```swift
// Calculate industry-standard adherence
let adherenceResults = try await adherenceService.calculateUserAdherence(
    userId: userId,
    startDate: startDate,
    endDate: endDate
)
```

## Real Data Examples

### Example 1: Daily Medication (Mesalamine)
```
Database Records:
- 2024-01-01: medication_taken=true, medication_type="Mesalamine"
- 2024-01-02: medication_taken=true, medication_type="Mesalamine"
- 2024-01-03: medication_taken=false, medication_type="Mesalamine"
- 2024-01-04: medication_taken=true, medication_type="Mesalamine"
...

Calculation:
- Expected Doses: 31 (daily for January)
- Actual Doses: 28 (from database records)
- Adherence: (28/31) × 100 = 90.3%
```

### Example 2: Weekly Medication (Infliximab)
```
Database Records:
- 2024-01-01: medication_taken=true, medication_type="Infliximab"
- 2024-01-08: medication_taken=true, medication_type="Infliximab"
- 2024-01-15: medication_taken=true, medication_type="Infliximab"
- 2024-01-22: medication_taken=true, medication_type="Infliximab"

Calculation:
- Expected Doses: 4 (weekly for 4 weeks)
- Actual Doses: 4 (from database records)
- Adherence: (4/4) × 100 = 100%
```

### Example 3: Bi-Weekly Medication (Adalimumab)
```
Database Records:
- 2024-01-01: medication_taken=true, medication_type="Adalimumab"
- 2024-01-15: medication_taken=true, medication_type="Adalimumab"
- 2024-01-29: medication_taken=true, medication_type="Adalimumab"

Calculation:
- Expected Doses: 2 (bi-weekly for 4 weeks)
- Actual Doses: 3 (from database records)
- Adherence: (3/2) × 100 = 150% (over-adherence)
```

## Medication Frequency Mapping

The system automatically determines medication frequency based on the `medication_type` field:

```swift
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
    default:
        return .daily
    }
}
```

## Quality Metrics from Real Data

### Timing Consistency
- **Source**: `created_at` timestamps from database
- **Calculation**: Standard deviation of time intervals between doses
- **Example**: If Mesalamine is taken at 8 AM ± 30 minutes daily, consistency = 95%

### Gap Analysis
- **Source**: Gaps between consecutive `medication_taken=true` records
- **Calculation**: Days between medication intake records
- **Example**: 3-day gap between doses = gap analysis alert

### Streak Analysis
- **Source**: Consecutive `medication_taken=true` records
- **Calculation**: Longest sequence of daily medication intake
- **Example**: 12 consecutive days of Mesalamine = 12-day streak

## Monthly Averaging Implementation

```swift
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
    let adherencePercentage = (Double(actualDoses) / Double(expectedDoses)) * 100.0
}
```

## API Endpoints Used

### 1. Journal Entries Endpoint
```
GET /api/journal/entries/{userId}?startDate={startDate}&endDate={endDate}
```

**Response:**
```json
[
  {
    "entry_id": 123,
    "user_id": "user_456",
    "entry_date": "2024-01-15",
    "medication_taken": true,
    "medication_type": "Mesalamine",
    "created_at": "2024-01-15T08:30:00Z"
  }
]
```

### 2. Medication Adherence Endpoint
```
GET /api/medication-adherence/{userId}?startDate={startDate}&endDate={endDate}
```

**Response:**
```json
{
  "overallAdherence": 87.5,
  "medications": {
    "Mesalamine": {
      "adherencePercentage": 90.3,
      "expectedDoses": 31,
      "actualDoses": 28,
      "trend": "improving"
    }
  }
}
```

## Integration with Evidence-Based Targets

The real medication data integrates with evidence-based targets:

```swift
// 1. Fetch real adherence data
let actualAdherence = medicationAdherenceService.overallAdherencePercentage

// 2. Adjust targets based on performance
let adjustedTarget = medicationAdherenceService.getEvidenceBasedTargetsAdjustedForAdherence(
    userProfile: userProfile,
    baseTargets: baseTargets.medicationAdherence
)

// 3. Set personalized goals
let personalizedTarget = MedicationAdherenceTarget(
    target: max(70.0, min(100.0, baseTargets.target + adherenceAdjustment)),
    warningThreshold: max(60.0, min(95.0, baseTargets.warningThreshold + adherenceAdjustment)),
    criticalThreshold: max(50.0, min(90.0, baseTargets.criticalThreshold + adherenceAdjustment))
)
```

## Benefits of Real Data Integration

### For Patients
- **Accurate Tracking**: Based on actual medication intake from journal entries
- **Real-time Updates**: Adherence calculated from live database records
- **Personalized Insights**: Targets adjusted based on individual performance
- **Historical Analysis**: Long-term adherence patterns and trends

### For Healthcare Providers
- **Industry Standards**: Uses recognized adherence calculation methods
- **Detailed Analytics**: Comprehensive adherence metrics from real data
- **Trend Analysis**: Long-term adherence patterns from database records
- **Quality Metrics**: Timing consistency and gap analysis from actual timestamps

### For the App
- **Evidence-Based**: Targets backed by clinical research and real data
- **Scalable**: Handles multiple medications and frequencies from database
- **Comprehensive**: Full adherence lifecycle tracking with real records
- **Reliable**: Based on actual user behavior, not estimates

## Conclusion

The medication adherence system now uses **real data** from your existing database:

1. **Database Source**: `journal_entries` table with `medication_taken` and `medication_type` fields
2. **Real-time Calculation**: Adherence calculated from actual user behavior
3. **Industry Standards**: Proper frequency-based calculation with monthly averaging
4. **Evidence-Based Integration**: Targets adjusted based on real performance data

This provides accurate, personalized medication adherence tracking that healthcare providers can trust and patients can use to improve their medication management! 🎉



