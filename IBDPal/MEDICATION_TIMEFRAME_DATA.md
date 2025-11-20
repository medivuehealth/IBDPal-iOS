# Medication Adherence Timeframe Data

## Current Configuration

The medication adherence calculation fetches data for a **3-month period** ending today.

### Default Timeframe
```swift
startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
endDate: Date() // Today
```

### Example for Today (December 2024)
- **Start Date**: September 1, 2024
- **End Date**: December 1, 2024
- **Total Days**: ~90 days
- **Total Weeks**: ~13 weeks
- **Total Months**: 3 months

## Database Query

The system executes this query to fetch medication data:

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
AND entry_date BETWEEN '2024-09-01' AND '2024-12-01'
AND medication_taken = true
ORDER BY entry_date ASC;
```

## Expected Doses by Medication Type

### Daily Medications (e.g., Mesalamine)
- **Expected Doses**: 90 doses (3 months × 30 days)
- **Calculation**: Total days in timeframe
- **Example**: If 28 doses taken → 28/90 = 31.1% adherence

### Weekly Medications (e.g., Infliximab)
- **Expected Doses**: 13 doses (3 months × 4.3 weeks)
- **Calculation**: Total days ÷ 7
- **Example**: If 12 doses taken → 12/13 = 92.3% adherence

### Bi-Weekly Medications (e.g., Adalimumab)
- **Expected Doses**: 6 doses (3 months × 2 bi-weeks)
- **Calculation**: Total days ÷ 14
- **Example**: If 6 doses taken → 6/6 = 100% adherence

### Monthly Medications (e.g., Vedolizumab)
- **Expected Doses**: 3 doses (3 months × 1 month)
- **Calculation**: Total days ÷ 30
- **Example**: If 3 doses taken → 3/3 = 100% adherence

## Monthly Breakdown

### Month 1 (September 2024)
- **Days**: 30 days
- **Mesalamine**: 30 expected doses
- **Infliximab**: 4 expected doses
- **Adalimumab**: 2 expected doses
- **Vedolizumab**: 1 expected dose

### Month 2 (October 2024)
- **Days**: 31 days
- **Mesalamine**: 31 expected doses
- **Infliximab**: 4 expected doses
- **Adalimumab**: 2 expected doses
- **Vedolizumab**: 1 expected dose

### Month 3 (November 2024)
- **Days**: 30 days
- **Mesalamine**: 30 expected doses
- **Infliximab**: 4 expected doses
- **Adalimumab**: 2 expected doses
- **Vedolizumab**: 1 expected dose

## Why 3 Months?

### 1. Sufficient Data for Analysis
- **Trend Analysis**: Enough data points to identify patterns
- **Monthly Averaging**: Accommodates different medication frequencies
- **Quality Metrics**: Sufficient data for timing consistency and gap analysis

### 2. Industry Standards
- **Clinical Guidelines**: 3 months is standard for adherence assessment
- **Provider Insights**: Long enough for meaningful healthcare provider analysis
- **Patient Motivation**: Recent enough to be relevant for patient engagement

### 3. Technical Benefits
- **Performance**: Not too much data to process quickly
- **Accuracy**: Recent data reflects current behavior patterns
- **Scalability**: Works for all medication frequencies

## Data Processing Flow

### 1. Database Fetch
```swift
// Fetch 3 months of medication records
let medicationRecords = try await databaseService.fetchMedicationRecordsWithAuth(
    userId: userId,
    userToken: userToken,
    startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
    endDate: Date()
)
```

### 2. Group by Medication
```swift
// Group records by medication type
let groupedRecords = Dictionary(grouping: medicationRecords) { $0.medicationName }
```

### 3. Calculate Adherence
```swift
// Calculate adherence for each medication
for (medicationName, records) in groupedRecords {
    let expectedDoses = calculateExpectedDoses(medicationName: medicationName, totalDays: 90)
    let actualDoses = records.count
    let adherencePercentage = (Double(actualDoses) / Double(expectedDoses)) * 100.0
}
```

### 4. Monthly Averaging
```swift
// Calculate monthly averages
let monthlyAverages = calculateMonthlyAverages(
    medicationRecords: records,
    medicationFrequency: frequency,
    startDate: startDate,
    endDate: endDate
)
```

## Sample Data Structure

### Input (Database Records)
```json
[
  {
    "entry_id": 123,
    "user_id": "user_456",
    "entry_date": "2024-09-15",
    "medication_taken": true,
    "medication_type": "Mesalamine",
    "created_at": "2024-09-15T08:30:00Z"
  },
  {
    "entry_id": 124,
    "user_id": "user_456",
    "entry_date": "2024-09-16",
    "medication_taken": true,
    "medication_type": "Mesalamine",
    "created_at": "2024-09-16T08:25:00Z"
  }
]
```

### Output (Adherence Results)
```json
{
  "Mesalamine": {
    "adherencePercentage": 87.5,
    "expectedDoses": 90,
    "actualDoses": 79,
    "trend": "improving",
    "qualityMetrics": {
      "timingConsistency": 85.2,
      "gapAnalysis": {
        "totalGaps": 3,
        "averageGapDays": 1.5
      }
    }
  }
}
```

## Benefits of 3-Month Timeframe

### For Patients
- **Recent Relevance**: Data reflects current medication behavior
- **Motivation**: Recent enough to be actionable
- **Pattern Recognition**: Long enough to identify trends

### For Healthcare Providers
- **Clinical Assessment**: Standard timeframe for adherence evaluation
- **Treatment Decisions**: Sufficient data for medication adjustments
- **Quality Metrics**: Reliable adherence measurement

### For the App
- **Performance**: Optimal balance of data volume and processing speed
- **Accuracy**: Recent data provides accurate adherence calculation
- **Scalability**: Works efficiently for all medication types and frequencies

## Conclusion

The 3-month timeframe provides the optimal balance of:
- **Sufficient data** for accurate adherence calculation
- **Recent relevance** for patient engagement
- **Industry standards** for healthcare provider assessment
- **Technical efficiency** for app performance

This timeframe ensures that medication adherence calculations are both accurate and actionable! 🎯







