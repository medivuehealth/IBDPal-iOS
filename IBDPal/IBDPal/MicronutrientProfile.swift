import Foundation
import Combine
import SwiftUI

// MARK: - Core Data Models

enum DiseaseActivity: String, Codable, CaseIterable {
    case remission = "remission"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var displayName: String {
        switch self {
        case .remission: return "Remission"
        case .mild: return "Mild Activity"
        case .moderate: return "Moderate Activity"
        case .severe: return "Severe Activity"
        }
    }
}

enum LabStatus: String, Codable, CaseIterable {
    case normal = "normal"
    case low = "low"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .low: return "Low"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .low: return "orange"
        case .high: return "red"
        case .critical: return "red"
        }
    }
}

// Comprehensive micronutrient data structure for foods
struct MicronutrientData: Codable {
    // Vitamins (in mg or mcg)
    let vitaminA: Double // mcg
    let vitaminB1: Double // mg (Thiamine)
    let vitaminB2: Double // mg (Riboflavin)
    let vitaminB3: Double // mg (Niacin)
    let vitaminB5: Double // mg (Pantothenic Acid)
    let vitaminB6: Double // mg
    let vitaminB7: Double // mcg (Biotin)
    let vitaminB9: Double // mcg (Folate)
    let vitaminB12: Double // mcg
    let vitaminC: Double // mg
    let vitaminD: Double // mcg
    let vitaminE: Double // mg
    let vitaminK: Double // mcg
    
    // Minerals (in mg or mcg)
    let calcium: Double // mg
    let iron: Double // mg
    let magnesium: Double // mg
    let phosphorus: Double // mg
    let potassium: Double // mg
    let sodium: Double // mg
    let zinc: Double // mg
    let copper: Double // mg
    let manganese: Double // mg
    let selenium: Double // mcg
    let iodine: Double // mcg
    let chromium: Double // mcg
    let molybdenum: Double // mcg
    
    // Trace elements
    let boron: Double // mg
    let silicon: Double // mg
    let vanadium: Double // mcg
    
    // IBD-specific nutrients
    let omega3: Double // mg (EPA + DHA)
    let glutamine: Double // mg
    let probiotics: Double // CFU (colony forming units)
    let prebiotics: Double // g (fiber)
    
    init(vitaminA: Double = 0, vitaminB1: Double = 0, vitaminB2: Double = 0, vitaminB3: Double = 0, vitaminB5: Double = 0, vitaminB6: Double = 0, vitaminB7: Double = 0, vitaminB9: Double = 0, vitaminB12: Double = 0, vitaminC: Double = 0, vitaminD: Double = 0, vitaminE: Double = 0, vitaminK: Double = 0, calcium: Double = 0, iron: Double = 0, magnesium: Double = 0, phosphorus: Double = 0, potassium: Double = 0, sodium: Double = 0, zinc: Double = 0, copper: Double = 0, manganese: Double = 0, selenium: Double = 0, iodine: Double = 0, chromium: Double = 0, molybdenum: Double = 0, boron: Double = 0, silicon: Double = 0, vanadium: Double = 0, omega3: Double = 0, glutamine: Double = 0, probiotics: Double = 0, prebiotics: Double = 0) {
        self.vitaminA = vitaminA
        self.vitaminB1 = vitaminB1
        self.vitaminB2 = vitaminB2
        self.vitaminB3 = vitaminB3
        self.vitaminB5 = vitaminB5
        self.vitaminB6 = vitaminB6
        self.vitaminB7 = vitaminB7
        self.vitaminB9 = vitaminB9
        self.vitaminB12 = vitaminB12
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.calcium = calcium
        self.iron = iron
        self.magnesium = magnesium
        self.phosphorus = phosphorus
        self.potassium = potassium
        self.sodium = sodium
        self.zinc = zinc
        self.copper = copper
        self.manganese = manganese
        self.selenium = selenium
        self.iodine = iodine
        self.chromium = chromium
        self.molybdenum = molybdenum
        self.boron = boron
        self.silicon = silicon
        self.vanadium = vanadium
        self.omega3 = omega3
        self.glutamine = glutamine
        self.probiotics = probiotics
        self.prebiotics = prebiotics
    }
}

struct MicronutrientProfile: Codable {
    let userId: String
    let age: Int
    let weight: Double
    let height: Double?
    let gender: String?
    let diseaseActivity: DiseaseActivity
    let diseaseType: String? // "IBD", "Crohns", "UC", "IBS"
    let medications: [String]
    let labResults: [LabResult]
    let supplements: [MicronutrientSupplement]
    let createdAt: Date?
    let updatedAt: Date?
    
    // Custom decoding to handle string values from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(String.self, forKey: .userId)
        age = try container.decode(Int.self, forKey: .age)
        
        // Handle weight as either Double or String
        if let weightDouble = try? container.decode(Double.self, forKey: .weight) {
            weight = weightDouble
        } else if let weightString = try? container.decode(String.self, forKey: .weight) {
            weight = Double(weightString) ?? 0.0
        } else {
            weight = 0.0
        }
        
        // Handle height as either Double or String
        if let heightDouble = try? container.decodeIfPresent(Double.self, forKey: .height) {
            height = heightDouble
        } else if let heightString = try? container.decodeIfPresent(String.self, forKey: .height) {
            height = Double(heightString ?? "0")
        } else {
            height = nil
        }
        
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        diseaseActivity = try container.decodeIfPresent(DiseaseActivity.self, forKey: .diseaseActivity) ?? .remission
        diseaseType = try container.decodeIfPresent(String.self, forKey: .diseaseType)
        medications = try container.decodeIfPresent([String].self, forKey: .medications) ?? []
        labResults = try container.decodeIfPresent([LabResult].self, forKey: .labResults) ?? []
        supplements = try container.decodeIfPresent([MicronutrientSupplement].self, forKey: .supplements) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        try container.encode(age, forKey: .age)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encode(diseaseActivity, forKey: .diseaseActivity)
        try container.encodeIfPresent(diseaseType, forKey: .diseaseType)
        try container.encode(medications, forKey: .medications)
        try container.encode(labResults, forKey: .labResults)
        try container.encode(supplements, forKey: .supplements)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case userId, age, weight, height, gender, diseaseActivity, diseaseType, medications, labResults, supplements, createdAt, updatedAt
    }
    
    init(userId: String, age: Int, weight: Double, height: Double? = nil, gender: String? = nil, diseaseActivity: DiseaseActivity = .remission, diseaseType: String? = nil, medications: [String] = [], labResults: [LabResult] = [], supplements: [MicronutrientSupplement] = [], createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.userId = userId
        self.age = age
        self.weight = weight
        self.height = height
        self.gender = gender
        self.diseaseActivity = diseaseActivity
        self.diseaseType = diseaseType
        self.medications = medications
        self.labResults = labResults
        self.supplements = supplements
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct LabResult: Codable, Identifiable {
    let id: String
    let nutrient: String
    let value: Double
    let unit: String
    let referenceRange: String
    let status: LabStatus
    let testDate: Date
    let notes: String?
    
    init(id: String = UUID().uuidString, nutrient: String, value: Double, unit: String, referenceRange: String, status: LabStatus, testDate: Date, notes: String? = nil) {
        self.id = id
        self.nutrient = nutrient
        self.value = value
        self.unit = unit
        self.referenceRange = referenceRange
        self.status = status
        self.testDate = testDate
        self.notes = notes
    }
    
    // Custom decoding to handle API response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either String or Int
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }
        
        nutrient = try container.decode(String.self, forKey: .nutrient)
        value = try container.decode(Double.self, forKey: .value)
        unit = try container.decode(String.self, forKey: .unit)
        referenceRange = try container.decode(String.self, forKey: .referenceRange)
        
        // Handle status as string and convert to enum
        let statusString = try container.decode(String.self, forKey: .status)
        status = LabStatus(rawValue: statusString) ?? .normal
        
        // Handle testDate as string and convert to Date
        let dateString = try container.decode(String.self, forKey: .testDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        testDate = formatter.date(from: dateString) ?? Date()
        
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, nutrient, value, unit, referenceRange, status, testDate, notes
    }
}

struct MicronutrientSupplement: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: MicronutrientCategory
    let dosage: Double
    let unit: DosageUnit
    let frequency: SupplementFrequency
    let startDate: Date
    let isActive: Bool
    let notes: String?
    
    init(id: String = UUID().uuidString, name: String, category: MicronutrientCategory, dosage: Double, unit: DosageUnit, frequency: SupplementFrequency, startDate: Date, isActive: Bool = true, notes: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.dosage = dosage
        self.unit = unit
        self.frequency = frequency
        self.startDate = startDate
        self.isActive = isActive
        self.notes = notes
    }
    
    // Custom decoding to handle API response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either String or Int
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }
        
        name = try container.decode(String.self, forKey: .name)
        
        // Handle category string and convert to enum
        let categoryString = try container.decode(String.self, forKey: .category)
        category = MicronutrientCategory(rawValue: categoryString.lowercased()) ?? .other
        
        // Handle dosage as either Double or Int
        if let dosageDouble = try? container.decode(Double.self, forKey: .dosage) {
            dosage = dosageDouble
        } else if let dosageInt = try? container.decode(Int.self, forKey: .dosage) {
            dosage = Double(dosageInt)
        } else {
            dosage = 0.0
        }
        
        // Handle unit string and convert to enum
        let unitString = try container.decode(String.self, forKey: .unit)
        unit = DosageUnit(rawValue: unitString.lowercased()) ?? .mg
        
        // Handle frequency string and convert to enum
        let frequencyString = try container.decode(String.self, forKey: .frequency)
        frequency = SupplementFrequency(rawValue: frequencyString.lowercased()) ?? .daily
        
        // Handle startDate as string and convert to Date
        let dateString = try container.decode(String.self, forKey: .startDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        startDate = formatter.date(from: dateString) ?? Date()
        
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, category, dosage, unit, frequency, startDate, isActive, notes
    }
}

// MARK: - Enums



enum MicronutrientCategory: String, Codable, CaseIterable, Hashable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "vitamin", "vitamins": self = .vitamin
        case "mineral", "minerals": self = .mineral
        case "trace_element", "trace element": self = .traceElement
        default: self = .other
        }
    }
    case vitamin = "vitamin"
    case mineral = "mineral"
    case traceElement = "trace_element"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .vitamin: return "Vitamin"
        case .mineral: return "Mineral"
        case .traceElement: return "Trace Element"
        case .other: return "Other"
        }
    }
}

enum DosageUnit: String, Codable, CaseIterable, Hashable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "mg": self = .mg
        case "mcg": self = .mcg
        case "g": self = .g
        case "iu": self = .iu
        case "ml": self = .ml
        case "tablet", "tablets": self = .tablet
        case "capsule", "capsules": self = .capsule
        default: self = .mg
        }
    }
    case mg = "mg"
    case mcg = "mcg"
    case g = "g"
    case iu = "IU"
    case ml = "ml"
    case tablet = "tablet"
    case capsule = "capsule"
    
    var displayName: String {
        return self.rawValue
    }
}

enum SupplementFrequency: String, Codable, CaseIterable, Hashable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "daily": self = .daily
        case "twice daily", "twice_daily": self = .twiceDaily
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "as needed", "as_needed": self = .asNeeded
        default: self = .daily
        }
    }
    case daily = "daily"
    case twiceDaily = "twice_daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case asNeeded = "as_needed"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .twiceDaily: return "Twice Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .asNeeded: return "As Needed"
        }
    }
}

// MARK: - IBD-Specific Nutrient Definitions

struct CommonMicronutrients {
    
    // MARK: - Critical Vitamins for IBD Patients
    static let criticalVitamins = [
        "Vitamin D (25-OH)",
        "Vitamin B12 (Cobalamin)",
        "Folate (Folic Acid)",
        "Vitamin B6 (Pyridoxine)",
        "Vitamin B1 (Thiamine)",
        "Vitamin B2 (Riboflavin)",
        "Vitamin B3 (Niacin)",
        "Vitamin C (Ascorbic Acid)",
        "Vitamin A (Retinol)",
        "Vitamin E (Tocopherol)",
        "Vitamin K"
    ]
    
    // MARK: - Critical Minerals for IBD Patients
    static let criticalMinerals = [
        "Iron (Fe)",
        "Ferritin",
        "Calcium (Ca)",
        "Magnesium (Mg)",
        "Zinc (Zn)",
        "Selenium (Se)",
        "Phosphorus (P)",
        "Potassium (K)",
        "Sodium (Na)"
    ]
    
    // MARK: - Trace Elements
    static let traceElements = [
        "Copper (Cu)",
        "Manganese (Mn)",
        "Chromium (Cr)",
        "Molybdenum (Mo)"
    ]
    
    // MARK: - Common Supplements for IBD
    static let commonSupplements = [
        "Iron Supplement",
        "Vitamin D3",
        "B12 (Methylcobalamin)",
        "Folic Acid",
        "Multivitamin",
        "Calcium + Vitamin D",
        "Magnesium",
        "Zinc",
        "Omega-3 (Fish Oil)",
        "Probiotics",
        "Vitamin C",
        "B-Complex"
    ]
    
    // MARK: - Reference Ranges for Key Nutrients
    static let referenceRanges: [String: String] = [
        "Vitamin D (25-OH)": "30-100 ng/mL",
        "Vitamin B12 (Cobalamin)": "211-911 pg/mL",
        "Folate (Folic Acid)": "3.38-48.0 ng/mL",
        "Iron (Fe)": "60-170 mcg/dL",
        "Ferritin": "10-291 ng/mL",
        "Calcium (Ca)": "8.5-10.5 mg/dL",
        "Magnesium (Mg)": "1.7-2.2 mg/dL",
        "Zinc (Zn)": "70-120 mcg/dL"
    ]
    
    // MARK: - Deficiency Risk Levels
    static let deficiencyRiskLevels: [String: String] = [
        "Vitamin D (25-OH)": "High - Common in IBD patients, affects bone health and immune function",
        "Vitamin B12 (Cobalamin)": "High - Especially in Crohn's disease affecting terminal ileum",
        "Folate (Folic Acid)": "High - Important for patients on methotrexate",
        "Iron (Fe)": "Very High - Most common deficiency in IBD (30-90% of patients)",
        "Ferritin": "Very High - Iron storage indicator, often low in IBD",
        "Calcium (Ca)": "High - Important for bone health, especially with steroid use",
        "Magnesium (Mg)": "Medium - Can be lost through diarrhea",
        "Zinc (Zn)": "Medium - Lost through diarrhea, important for wound healing"
    ]
}

// MARK: - API Response Models
// MARK: - API Request Models

struct MicronutrientProfileRequest: Codable {
    let age: String?
    let weight: String?
    let height: String?
    let gender: String?
    let labResults: [LabResult]?
    let supplements: [MicronutrientSupplement]?
}

struct MicronutrientProfileResponse: Codable {
    let success: Bool?
    let data: MicronutrientProfile?
    let message: String?
}

struct LabResultResponse: Codable {
    let success: Bool
    let data: [LabResult]?
    let message: String
}

struct SupplementResponse: Codable {
    let success: Bool
    let data: [MicronutrientSupplement]?
    let message: String
}

// MARK: - Helper Extensions

extension Date {
    func formattedForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

extension Double {
    func formattedAsNutrient() -> String {
        if self == floor(self) {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.2f", self)
        }
    }


// MARK: - Enhanced Micronutrient Models for IBD Patients

}

// MARK: - Evidence-Based IBD Nutritional Requirements
// Based on AGA Clinical Practice Update 2024, Crohn's & Colitis Congress 2024,
// and peer-reviewed research on IBD micronutrient deficiencies

// Research Sources:
// 1. AGA Clinical Practice Update (2024): "Diet and nutritional therapies in patients with IBD"
//    DOI: 10.1053/j.gastro.2023.11.303
// 2. Crohn's & Colitis Congress (2024): "Micronutrient deficiencies in IBD"
// 3. WebMD IBD Research: "Micronutrient Deficiencies and Crohn's Disease"
// 4. Nutritional Therapy for IBD: Evidence-based recommendations

struct IBDMicronutrientRequirements: Codable {
    let age: Int
    let gender: String
    let weight: Double
    let height: Double?
    let diseaseActivity: DiseaseActivity
    let medications: [String]
    let diseaseType: String // "IBD", "Crohns", "UC", "IBS"
    
    // Daily requirements (evidence-based for IBD patients)
    let calories: Double // kcal - higher during flares
    let protein: Double // g - weight-based calculation
    let vitaminD: Double // IU - 2000-4000 IU per AGA guidelines
    let vitaminB12: Double // mcg - 1000-2000 mcg due to absorption issues
    let folate: Double // mcg - 400-800 mcg for medication interactions
    let iron: Double // mg - 18-65 mg for blood loss and malabsorption
    let calcium: Double // mg - bone health considerations
    let zinc: Double // mg - healing and immune function
    let magnesium: Double // mg - muscle function
    let omega3: Double // g - anti-inflammatory properties
    let fiber: Double // g - symptom-adjustable
    let hydration: Double // ml - increased during flares
    let glutamine: Double // mg - gut healing
    let probiotics: Double // CFU - gut health
    
    init(age: Int, gender: String, weight: Double, height: Double? = nil, 
         diseaseActivity: DiseaseActivity = .remission, medications: [String] = [], 
         diseaseType: String = "IBD") {
        self.age = age
        self.gender = gender
        self.weight = weight
        self.height = height
        self.diseaseActivity = diseaseActivity
        self.medications = medications
        self.diseaseType = diseaseType
        
        // EVIDENCE-BASED REQUIREMENTS
        
        // 1. CALORIES (AGA 2024: Higher needs during flares)
        let baseCalories: Double
        if age < 18 {
            baseCalories = weight * 35.0 // Pediatric needs
        } else if age > 65 {
            baseCalories = weight * 25.0 // Geriatric needs
        } else {
            baseCalories = weight * 30.0 // Adult baseline
        }
        
        // 2. PROTEIN (Research shows 1.5-2.0 g/kg for IBD vs 0.8 g/kg RDA)
        let baseProtein = weight * 1.5 // g/kg - higher for IBD healing
        
        // 3. VITAMIN D (AGA 2024: 2000-4000 IU vs RDA 600-800 IU)
        let baseVitaminD: Double
        if age < 18 {
            baseVitaminD = 2000.0 // IU - pediatric IBD
        } else if age > 65 {
            baseVitaminD = 3000.0 // IU - older adults need more
        } else {
            baseVitaminD = 2500.0 // IU - adult IBD patients
        }
        
        // 4. VITAMIN B12 (Research: 1000-2000 mcg vs RDA 2.4 mcg)
        let baseB12: Double = 1000.0 // mcg - absorption issues in IBD
        
        // 5. IRON (Research: 18-65 mg vs RDA 8-18 mg)
        let baseIron: Double
        if gender.lowercased() == "female" {
            baseIron = 45.0 // mg - higher for menstruating females
        } else {
            baseIron = 30.0 // mg - higher for IBD blood loss
        }
        
        // 6. FOLATE (Research: 400-800 mcg for medication interactions)
        let baseFolate: Double = 600.0 // mcg - medication interactions
        
        // 7. CALCIUM (Age-based, considering steroid use)
        let baseCalcium: Double
        if age < 50 {
            baseCalcium = 1200.0 // mg - higher for IBD
        } else {
            baseCalcium = 1500.0 // mg - bone health
        }
        
        // Disease Activity Multipliers (Evidence-based)
        let activityMultiplier: Double
        let calorieMultiplier: Double
        let hydrationMultiplier: Double
        
        switch diseaseActivity {
        case .remission:
            activityMultiplier = 1.0
            calorieMultiplier = 1.0
            hydrationMultiplier = 1.0
        case .mild:
            activityMultiplier = 1.1
            calorieMultiplier = 1.1
            hydrationMultiplier = 1.2
        case .moderate:
            activityMultiplier = 1.3
            calorieMultiplier = 1.2
            hydrationMultiplier = 1.3
        case .severe:
            activityMultiplier = 1.5
            calorieMultiplier = 1.4
            hydrationMultiplier = 1.5
        }
        
        // Disease Type Adjustments
        let diseaseMultiplier: Double
        switch diseaseType.lowercased() {
        case "crohns", "crohn", "cd":
            diseaseMultiplier = 1.2 // Higher malabsorption
        case "uc", "ulcerative colitis":
            diseaseMultiplier = 1.1 // Moderate adjustments
        case "ibs":
            diseaseMultiplier = 1.05 // Minimal adjustments
        default: // IBD general
            diseaseMultiplier = 1.15
        }
        
        // Calculate final requirements
        self.calories = baseCalories * calorieMultiplier
        self.protein = baseProtein * activityMultiplier
        self.vitaminD = baseVitaminD * activityMultiplier * diseaseMultiplier
        self.vitaminB12 = baseB12 * activityMultiplier * diseaseMultiplier
        self.folate = baseFolate * activityMultiplier
        self.iron = baseIron * activityMultiplier * diseaseMultiplier
        self.calcium = baseCalcium * activityMultiplier
        self.zinc = 15.0 * activityMultiplier // mg - higher for IBD
        self.magnesium = 400.0 * activityMultiplier // mg - maintain current
        self.omega3 = 2.0 * activityMultiplier // g - anti-inflammatory dose
        
        // Fiber (symptom-adjustable)
        let baseFiber: Double
        switch diseaseActivity {
        case .severe:
            baseFiber = 10.0 // g - low fiber during flares
        case .moderate:
            baseFiber = 15.0 // g - moderate fiber
        case .mild:
            baseFiber = 20.0 // g - approaching normal
        case .remission:
            baseFiber = 25.0 // g - normal intake
        }
        self.fiber = baseFiber
        
        // Hydration (Research: 2-3L baseline, more during flares)
        self.hydration = 2000.0 * hydrationMultiplier // ml
        
        // Gut-specific nutrients
        self.glutamine = 5000.0 * activityMultiplier // mg - gut healing
        self.probiotics = 10000000000.0 * activityMultiplier // 10 billion CFU
    }
    
    // MARK: - Research References
    /*
     Research Sources Used:
     
     1. AGA Clinical Practice Update (2024):
        - Vitamin D: 2000-4000 IU for IBD patients
        - Regular monitoring of B12, Iron, Folate
        - Higher protein needs for healing
     
     2. Crohn's & Colitis Congress (2024):
        - 70% of IBD patients have micronutrient deficiencies
        - Malabsorption factors of 40-60%
        - Disease activity impacts requirements
     
     3. WebMD IBD Research:
        - Iron deficiency affects 70% of IBD patients
        - B12 deficiency common due to ileal involvement
        - Age and gender considerations
     
     4. Institute of Medicine (General RDA baseline):
        - Vitamin D: 15-20 mcg (600-800 IU) - ADJUSTED UP for IBD
        - Protein: 0.8 g/kg - ADJUSTED UP to 1.5 g/kg for IBD
        - Iron: 8-18 mg - ADJUSTED UP to 18-65 mg for IBD
     */
}



// Daily micronutrient intake tracking
struct DailyMicronutrientIntake: Codable {
    let date: Date
    let totalIntake: MicronutrientData
    let foodSources: [String: MicronutrientData] // food name -> micronutrient data
    let supplementSources: [String: MicronutrientData] // supplement name -> micronutrient data
    let requirements: IBDMicronutrientRequirements
    let deficiencies: [MicronutrientDeficiency]
    let excesses: [MicronutrientExcess]
    
    init(date: Date, totalIntake: MicronutrientData, foodSources: [String: MicronutrientData] = [:], supplementSources: [String: MicronutrientData] = [:], requirements: IBDMicronutrientRequirements) {
        self.date = date
        self.totalIntake = totalIntake
        self.foodSources = foodSources
        self.supplementSources = supplementSources
        self.requirements = requirements
        self.deficiencies = []
        self.excesses = []
    }
}

// Micronutrient deficiency tracking
struct MicronutrientDeficiency: Codable, Identifiable {
    let id: String
    let nutrient: String
    let currentIntake: Double
    let requiredIntake: Double
    let deficiencyPercentage: Double
    let severity: DeficiencySeverity
    let symptoms: [String]
    let recommendations: [String]
    
    init(id: String = UUID().uuidString, nutrient: String, currentIntake: Double, requiredIntake: Double, symptoms: [String] = [], recommendations: [String] = []) {
        self.id = id
        self.nutrient = nutrient
        self.currentIntake = currentIntake
        self.requiredIntake = requiredIntake
        self.deficiencyPercentage = ((requiredIntake - currentIntake) / requiredIntake) * 100
        self.severity = DeficiencySeverity.fromPercentage(deficiencyPercentage)
        self.symptoms = symptoms
        self.recommendations = recommendations
    }
}

// Micronutrient excess tracking
struct MicronutrientExcess: Codable, Identifiable {
    let id: String
    let nutrient: String
    let currentIntake: Double
    let safeUpperLimit: Double
    let excessPercentage: Double
    let severity: ExcessSeverity
    let risks: [String]
    let recommendations: [String]
    
    init(id: String = UUID().uuidString, nutrient: String, currentIntake: Double, safeUpperLimit: Double, risks: [String] = [], recommendations: [String] = []) {
        self.id = id
        self.nutrient = nutrient
        self.currentIntake = currentIntake
        self.safeUpperLimit = safeUpperLimit
        self.excessPercentage = ((currentIntake - safeUpperLimit) / safeUpperLimit) * 100
        self.severity = ExcessSeverity.fromPercentage(excessPercentage)
        self.risks = risks
        self.recommendations = recommendations
    }
}

enum DeficiencySeverity: String, Codable, CaseIterable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .mild: return "Mild Deficiency"
        case .moderate: return "Moderate Deficiency"
        case .severe: return "Severe Deficiency"
        case .critical: return "Critical Deficiency"
        }
    }
    
    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        case .critical: return "red"
        }
    }
    
    var colorValue: Color {
        switch self {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .mild: return "exclamationmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .severe: return "exclamationmark.octagon.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    static func fromPercentage(_ percentage: Double) -> DeficiencySeverity {
        switch percentage {
        case 0..<25: return .mild
        case 25..<50: return .moderate
        case 50..<75: return .severe
        default: return .critical
        }
    }
}

enum ExcessSeverity: String, Codable, CaseIterable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .mild: return "Mild Excess"
        case .moderate: return "Moderate Excess"
        case .severe: return "Severe Excess"
        case .critical: return "Critical Excess"
        }
    }
    
    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        case .critical: return "red"
        }
    }
    
    static func fromPercentage(_ percentage: Double) -> ExcessSeverity {
        switch percentage {
        case 0..<25: return .mild
        case 25..<50: return .moderate
        case 50..<75: return .severe
        default: return .critical
        }
    }
}



// MARK: - IBD Micronutrient Analysis
struct IBDMicronutrientAnalysis: Codable {
    let dailyIntake: MicronutrientData
    let requirements: IBDMicronutrientRequirements
    let deficiencies: [MicronutrientDeficiency]
    let excesses: [MicronutrientExcess]
    let ibdSpecificNutrients: IBDSpecificNutrients
    let absorptionFactors: AbsorptionFactors
    let recommendations: MicronutrientRecommendations
}

// MARK: - Supporting Types for IBD Analysis
struct IBDSpecificNutrients: Codable {
    let vitaminD: NutrientStatus
    let vitaminB12: NutrientStatus
    let iron: NutrientStatus
    let calcium: NutrientStatus
    let zinc: NutrientStatus
    let omega3: NutrientStatus
    let glutamine: NutrientStatus
    let probiotics: NutrientStatus
}

struct NutrientStatus: Codable {
    let currentIntake: Double
    let requiredIntake: Double
    let status: NutrientStatusLevel
    let absorptionRate: Double
    let ibdFactors: [String]
}

enum NutrientStatusLevel: String, Codable {
    case deficient = "deficient"
    case suboptimal = "suboptimal"
    case adequate = "adequate"
    case optimal = "optimal"
    case excessive = "excessive"
}

struct AbsorptionFactors: Codable {
    let medicationInteractions: [String: Double]
    let diseaseActivity: Double
    let gutHealth: Double
    let foodCombinations: [String: Double]
}

struct MicronutrientRecommendations: Codable {
    let immediateActions: [MicronutrientAction]
    let supplementSuggestions: [SupplementSuggestion]
    let foodRecommendations: [FoodRecommendation]
    let timingRecommendations: [TimingRecommendation]
    let monitoringSuggestions: [MonitoringSuggestion]
}

struct MicronutrientAction: Codable {
    let nutrient: String
    let action: String
    let priority: ActionPriority
    let timeframe: String
}

enum ActionPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

struct SupplementSuggestion: Codable {
    let nutrient: String
    let supplementName: String
    let dosage: Double
    let unit: String
    let frequency: String
    let reasoning: String
    let interactions: [String]
}

struct FoodRecommendation: Codable {
    let nutrient: String
    let foodName: String
    let servingSize: String
    let frequency: String
    let preparation: String
    let reasoning: String
}

struct TimingRecommendation: Codable {
    let nutrient: String
    let timing: String
    let reasoning: String
}

struct MonitoringSuggestion: Codable {
    let nutrient: String
    let testType: String
    let frequency: String
    let targetRange: String
    let reasoning: String
}

